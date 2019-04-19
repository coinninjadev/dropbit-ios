//
//  WalletAddressDataWorker.swift
//  CoinKeeper
//
//  Created by Ben Winters on 6/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import Moya
import PromiseKit
import PhoneNumberKit
import UIKit
import os.log

// swiftlint:disable file_length
protocol WalletAddressDataWorkerType: AnyObject {

  var targetWalletAddressCount: Int { get }

  /**
   This will fulfill Void early if not verified.
   */
  func updateServerPoolAddresses(in context: NSManagedObjectContext) -> Promise<Void>

  /**
   This will retrieve and register addresses from the wallet manager based on the lastReceiveIndex and the provided `number` (quantity).
   This may be used independently of the updateServerAddresses function.
   */
  func registerAndPersistServerAddresses(number: Int, in context: NSManagedObjectContext) -> Promise<Void>

  func fetchAndFulfillReceivedAddressRequests(in context: NSManagedObjectContext) -> Promise<Void>

  func updateReceivedAddressRequests(in context: NSManagedObjectContext) -> Promise<Void>

  func updateSentAddressRequests(in context: NSManagedObjectContext) -> Promise<[PendingInvitationData]>

  func cancelInvitation(withID invitationID: String, in context: NSManagedObjectContext) -> Promise<Void>

  /// Useful for debugging and setting a clean slate during initial registration
  func deleteAllAddressesOnServer() -> Promise<Void>

}

extension WalletAddressDataWorkerType {

  var targetWalletAddressCount: Int { return 5 }

}

// swiftlint:disable type_body_length
class WalletAddressDataWorker: WalletAddressDataWorkerType {

  let walletManager: WalletManagerType
  let persistenceManager: PersistenceManagerType
  let networkManager: NetworkManagerType
  let analyticsManager: AnalyticsManagerType
  let phoneNumberKit: PhoneNumberKit
  unowned var invitationDelegate: InvitationWorkerDelegate

  private let logger = OSLog(subsystem: "com.coinninja.transactionDataWorker", category: "wallet_address_data_worker")

  init(
    walletManager: WalletManagerType,
    persistenceManager: PersistenceManagerType,
    networkManager: NetworkManagerType,
    analyticsManager: AnalyticsManagerType,
    phoneNumberKit: PhoneNumberKit,
    invitationWorkerDelegate: InvitationWorkerDelegate
    ) {
    self.walletManager = walletManager
    self.persistenceManager = persistenceManager
    self.networkManager = networkManager
    self.analyticsManager = analyticsManager
    self.phoneNumberKit = phoneNumberKit
    self.invitationDelegate = invitationWorkerDelegate
  }

  func updateServerPoolAddresses(in context: NSManagedObjectContext) -> Promise<Void> {
    let verificationStatus = persistenceManager.userVerificationStatus(in: context)
    guard verificationStatus == .verified else { return Promise { $0.fulfill(()) } }

    let addressSource = self.walletManager.createAddressDataSource()

    return self.networkManager.getWalletAddresses()
      .then(in: context) { self.checkAddressIntegrity(of: $0, addressDataSource: addressSource, in: context) }
      .then(in: context) { self.removeUsedServerAddresses(from: $0, in: context) }
      .then(in: context) { self.registerAndPersistServerAddresses(number: $0, in: context) }
  }

  func registerAndPersistServerAddresses(number: Int, in context: NSManagedObjectContext) -> Promise<Void> {
    guard number > 0 else { return Promise { $0.fulfill(()) } }

    let verificationStatus = persistenceManager.userVerificationStatus(in: context)
    guard verificationStatus == .verified else { return Promise { $0.fulfill(()) } }

    let addressDataSource = self.walletManager.createAddressDataSource()
    let metaAddresses = addressDataSource.nextAvailableReceiveAddresses(number: number, forServerPool: true, indicesToSkip: [], in: context)
    let addressesWithPubKeys: [MetaAddress] = metaAddresses.compactMap { MetaAddress(cnbMetaAddress: $0) }
    let addAddressBodies = addressesWithPubKeys.map { AddWalletAddressBody(address: $0.address,
                                                                           addressPubkey: $0.addressPubKey,
                                                                           walletAddressRequestId: nil) }

    // Construct/call array of network request promises from address strings
    return when(fulfilled: addAddressBodies.map { self.networkManager.addWalletAddress(body: $0) })
      .then(in: context) { (responses: [WalletAddressResponse]) -> Promise<Void> in
        os_log("Added wallet addresses to server:", log: self.logger, type: .debug)
        responses.forEach { os_log("\t%{private}@", log: self.logger, type: .debug, $0.address)}

        return self.persistenceManager.persistAddedWalletAddresses(from: responses, metaAddresses: metaAddresses, in: context)
    }
  }

  func fetchAndFulfillReceivedAddressRequests(in context: NSManagedObjectContext) -> Promise<Void> {
    return self.networkManager.getWalletAddressRequests(forSide: .received)
      // We don't filter status cases here because mapAndFulfillAddressRequests will
      // only handle .new without address, and we want to persist all invitations regardless of their status.
      .then(in: context) { self.mapAndFulfillAddressRequests(with: $0, in: context) }
      .get(in: context) { self.persistReceivedAddressRequests($0, in: context) }.asVoid()
  }

  func updateReceivedAddressRequests(in context: NSManagedObjectContext) -> Promise<Void> {
    guard persistenceManager.userId(in: context) != nil else {
      return Promise { $0.fulfill(()) }
    }

    return self.networkManager.getWalletAddressRequests(forSide: .received)
      .get(in: context) { self.persistReceivedAddressRequests($0, in: context) }
      .get(in: context) { _ in self.linkFulfilledAddressRequestsWithTransaction(in: context)
      }.asVoid()
  }

  /// Promise value is an array of PendingInvitationData which were successfully broadcast, currently a single object or empty.
  func updateSentAddressRequests(in context: NSManagedObjectContext) -> Promise<[PendingInvitationData]> {
    guard persistenceManager.userId(in: context) != nil else {
      return Promise { $0.fulfill([]) }
    }

    return checkForExpiredAndCanceledSentInvitations(in: context)
      .then(in: context) { self.handleUnacknowledgedSentInvitations(in: context) }
      .then(in: context) { self.ensureSentAddressRequestIntegrity(in: context) }
      .then(in: context) { self.checkAndExecuteSentInvitations(in: context) }
  }

  /// Update request on the server and if it succeeds, update the local CKMInvitation and PendingInvitationData.
  func cancelInvitation(withID invitationID: String, in context: NSManagedObjectContext) -> Promise<Void> {
    let request = WalletAddressRequest(walletAddressRequestStatus: .canceled)
    return networkManager.updateWalletAddressRequest(for: invitationID, with: request)
      .done(in: context) { self.cancelInvitationLocally(with: $0, in: context) }
  }

  func cancelInvitationLocally(with response: WalletAddressRequestResponse, in context: NSManagedObjectContext) {

    guard let foundInvitation = CKMInvitation.find(withId: response.id, in: context), foundInvitation.status != .canceled else { return }

    self.persistenceManager.removePendingInvitationData(with: response.id)
    foundInvitation.status = .canceled
    foundInvitation.transaction?.temporarySentTransaction.map { context.delete($0) }
  }

  func handleUnacknowledgedSentInvitations(in context: NSManagedObjectContext) -> Promise<Void> {
    return self.networkManager.getWalletAddressRequests(forSide: .sent)
      .then(in: context) { (responses: [WalletAddressRequestResponse]) -> Promise<Void> in
        let serverAcknowledgedIds = responses.compactMap { $0.metadata?.requestId }.asSet()
        let unacknowledgedInvitations = self.persistenceManager.getUnacknowledgedInvitations(in: context)

        for invitation in unacknowledgedInvitations {
          if serverAcknowledgedIds.contains(invitation.sanitizedId),
            let response = responses.first(where: { return $0.metadata?.requestId == invitation.sanitizedId }) {
            self.acknowledgeInvitation(invitation, response: response, in: context)
          } else {
            context.delete(invitation)
          }
        }

        return self.cancelUnknownInvitationRequestsIfNecessary(responses, in: context)
    }
  }

  private func cancelUnknownInvitationRequestsIfNecessary(_ responses: [WalletAddressRequestResponse],
                                                          in context: NSManagedObjectContext) -> Promise<Void> {
    let allLocalInvitationIds = persistenceManager.getAllInvitations(in: context).map { $0.id }.asSet()
    let responseIds = responses.filter { $0.statusCase == .new }.map { $0.id }.asSet()
    guard allLocalInvitationIds.isNotEmpty else { return Promise.value(()) }

    let bogusIds = responseIds.subtracting(allLocalInvitationIds)
    let invitationCancelPromises = bogusIds.map { self.cancelInvitation(withID: $0, in: context).asVoid() }

    return when(resolved: invitationCancelPromises).asVoid()
  }

  private func acknowledgeInvitation(_ invitation: CKMInvitation,
                                     response: WalletAddressRequestResponse,
                                     in context: NSManagedObjectContext) {

    context.performAndWait {
      // In this edge case where the initial invitation wasn't immediately acknowledged due to the
      // server response being interrupted, we pass nil instead of the original shared payload.

      let outgoingTransactionData = OutgoingTransactionData(
        txid: CKMTransaction.invitationTxidPrefix + response.id,
        contactName: invitation.counterpartyName ?? "",
        contactPhoneNumber: invitation.counterpartyPhoneNumber?.asGlobalPhoneNumber,
        contactPhoneNumberHash: invitation.counterpartyPhoneNumber?.phoneNumberHash ?? "",
        destinationAddress: "",
        amount: invitation.btcAmount,
        feeAmount: invitation.fees,
        sentToSelf: false,
        requiredFeeRate: nil,
        sharedPayloadDTO: nil)

      self.persistenceManager.acknowledgeInvitation(with: outgoingTransactionData, response: response, in: context)
    }
  }

  /**
   Check that address requests on server are up to date with local objects and attempt to update server if necessary.
   Failed attempts to update recover within this function.
   */
  private func ensureSentAddressRequestIntegrity(in context: NSManagedObjectContext) -> Promise<Void> {
    return self.networkManager.getWalletAddressRequests(forSide: .sent)
      .then(in: context) { (responses: [WalletAddressRequestResponse]) -> Promise<Void> in
        let newRequests = responses.filter { $0.statusCase == .new }

        // Identify any "new" requests that should be marked completed because they already have a txid locally
        let detailsToPatchAsCompleted: [AddressRequestPatch] = self.detailsToMarkCompleted(for: newRequests, in: context)

        /// commented out automatic cancelation temporarily 2018AUG16 (BJM)
        //        let patchAsCompletedRequestIds: [String] = detailsToPatchAsCompleted.map { $0.requestId }
        //        let cancellableNewRequests: [WalletAddressRequestResponse] = newRequests.filter { !patchAsCompletedRequestIds.contains($0.id) }

        // Only pass in the responses which will not be marked as completed
        //        let requestIdsToPatchAsCanceled: [String] = self.idsToCancelIfNegativeBalance(requests: cancellableNewRequests, in: context)

        // Create a promise for each patch and return when they have all fulfilled.
        // Use asVoid to so that we can create the `when` array with different promise value types.
        let patchCompletedPromises = detailsToPatchAsCompleted.map { patch in
          self.networkManager.updateWalletAddressRequest(withPatch: patch).asVoid()
        }
        //        let patchCanceledPromises = requestIdsToPatchAsCanceled.map { self.cancelInvitation(withID: $0, in: context).asVoid() }
        let allPatchPromises = patchCompletedPromises // + patchCanceledPromises

        // Ignore promise rejection in case of network failure by using `resolved`. Then return a promise of Void.
        return when(resolved: allPatchPromises).then { _ in Promise.value(()) }
    }
  }

  private func detailsToMarkCompleted(for requests: [WalletAddressRequestResponse],
                                      in context: NSManagedObjectContext) -> [AddressRequestPatch] {
    return requests.compactMap { response in
      // Check if invitation matching request has a non-empty txid, prepare a patch
      if let invitation = CKMInvitation.find(withId: response.id, in: context), (invitation.txid ?? "").isNotEmpty {
        let patch = WalletAddressRequest(walletAddressRequestStatus: .completed, txid: invitation.txid)
        return (response.id, patch)
      } else {
        return nil
      }
    }
  }

  /// commented out on 2018AUG16 due to temporarily halting automatic cancelation of DropBits (BJM)
  //  private func idsToCancelIfNegativeBalance(requests: [WalletAddressRequestResponse],
  //                                            in context: NSManagedObjectContext) -> [String] {
  //    if walletManager.balance(in: context) >= 0 {
  //      return []
  //    } else {
  //      // Balance is negative, so we need to cancel all outstanding requests
  //      return requests.map { $0.id }
  //    }
  //  }

  /// Invitation objects with a txid that does not match its transaction?.txid will search for a Transaction that does match.
  func linkFulfilledAddressRequestsWithTransaction(in context: NSManagedObjectContext) {
    let statusPredicate = CKPredicate.Invitation.withStatuses([.completed])
    let hasTxidPredicate = CKPredicate.Invitation.hasTxid()

    // Ignore invitations whose transaction already matches the txid
    let notMatchingTxidPredicate = CKPredicate.Invitation.transactionTxidDoesNotMatch()

    let fetchRequest: NSFetchRequest<CKMInvitation> = CKMInvitation.fetchRequest()
    fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [statusPredicate, hasTxidPredicate, notMatchingTxidPredicate])

    do {
      let updatableInvitations = try context.fetch(fetchRequest)
      os_log("Found %d updatable invitations", log: self.logger, type: .debug, updatableInvitations.count)

      updatableInvitations.forEach { invitation in
        guard let invitationTxid = invitation.txid else { return }

        if let targetTransaction = CKMTransaction.find(byTxid: invitationTxid, in: context) {
          os_log("Found transaction matching the invitation.txid, will update relationship", log: self.logger, type: .debug)
          let placeholderTransaction = invitation.transaction

          invitation.transaction = targetTransaction

          if let placeholder = placeholderTransaction {
            context.delete(placeholder)
            os_log("Deleted placeholder transaction", log: self.logger, type: .debug)
          }
        }
      }

    } catch {
      os_log("Failed to fetch updatable invitations: %@", log: self.logger, type: .error, error.localizedDescription)
    }
  }

  func deleteAllAddressesOnServer() -> Promise<Void> {
    return self.networkManager.getWalletAddresses()
      .map { $0.compactMap { $0.address} }
      .then { self.deleteAddressesFromServer($0) }.asVoid()
  }

  /// Return value is array of valid WalletAddressResponse, after any invalid ones have been deleted from the server
  func checkAddressIntegrity(of responses: [WalletAddressResponse],
                             addressDataSource: AddressDataSourceType,
                             in context: NSManagedObjectContext) -> Promise<[WalletAddressResponse]> {

    var validResponses: [WalletAddressResponse] = []
    var missingPubKeyResponses: [WalletAddressResponse] = []
    var foreignAddressResponses: [WalletAddressResponse] = []

    for response in responses {
      let addressIsForeign = addressDataSource.checkAddressExists(for: response.address, in: context) == nil

      // Check validity in decreasing order of severity
      if addressIsForeign {
        foreignAddressResponses.append(response)
      } else if response.addressPubkey == nil {
        missingPubKeyResponses.append(response)
      } else {
        validResponses.append(response)
      }
    }

    let invalidAddresses = (missingPubKeyResponses + foreignAddressResponses).map { $0.address }

    return self.sendFlareIfNeeded(withBadResponses: foreignAddressResponses, goodResponses: validResponses)
      .then(in: context) { _ in self.deleteAddressesFromServer(invalidAddresses) }
      .then(in: context) { _ in Promise.value(validResponses) }
  }

  // MARK: - Private

  /// To be revised once flare service is available
  private func sendFlareIfNeeded(withBadResponses badResponses: [WalletAddressResponse],
                                 goodResponses: [WalletAddressResponse]) -> Promise<[WalletAddressResponse]> {

    let goodAddresses = goodResponses.compactMap { $0.address }
    os_log("Valid addresses on server (%d): %@", log: self.logger, type: .debug, goodAddresses.count, goodAddresses)

    if badResponses.isNotEmpty {
      let responseDescriptions = badResponses.map { $0.jsonDescription }.joined(separator: "; ")
      let eventValue = AnalyticsEventValue(key: .foreignWalletAddressDetected, value: responseDescriptions)
      self.analyticsManager.track(event: .foreignWalletAddressDetected, with: eventValue)
      os_log("Foreign addresses detected on server (%d): %@", log: self.logger, type: .error, badResponses.count, responseDescriptions)
    }

    return .value(goodResponses)
  }

  /// Returns the number of addresses that should be added to server.
  private func removeUsedServerAddresses(from responses: [WalletAddressResponse], in context: NSManagedObjectContext) -> Promise<Int> {
    return self.ensureLocalServerAddressParity(with: responses, in: context)
      .then(in: context) { self.deleteUsedAddresses(allServerAddresses: $0, in: context) }
  }

  private func checkForExpiredAndCanceledSentInvitations(in context: NSManagedObjectContext) -> Promise<Void> {
    return self.networkManager.getWalletAddressRequests(forSide: .sent)
      .get(in: context) { self.removeCanceledInvitationsIfNecessary(responses: $0, in: context) }
      .done(in: context) { self.expireInvitationsIfNecessary(responses: $0, in: context) }
  }

  private func removeCanceledInvitationsIfNecessary(responses: [WalletAddressRequestResponse], in context: NSManagedObjectContext) {
    let canceledRequest = responses.filter { $0.statusCase == .canceled }
    canceledRequest.forEach { response in
      self.cancelInvitationLocally(with: response, in: context)
    }
  }

  private func expireInvitationsIfNecessary(responses: [WalletAddressRequestResponse], in context: NSManagedObjectContext) {
    let expiredRequests = responses.filter { $0.statusCase == .expired }
    expiredRequests.forEach { response in
      CKMInvitation.updateIfExists(withAddressRequestResponse: response, side: .sent, isAcknowledged: true, in: context)
    }
  }

  //checks for invitations that were canceled by reciever or server
  private func checkForCanceledSentInvitations(in context: NSManagedObjectContext) -> Promise<Void> {
    return self.networkManager.getWalletAddressRequests(forSide: .sent)
      .get(in: context) { (responses: [WalletAddressRequestResponse]) in
        let canceledRequest = responses.filter { $0.statusCase == .canceled }
        canceledRequest.forEach { response in
          self.cancelInvitationLocally(with: response, in: context)
        }
      }.asVoid()
  }

  private func checkAndExecuteSentInvitations(in context: NSManagedObjectContext) -> Promise<[PendingInvitationData]> {
    return invitationDelegate.fetchAndHandleSentWalletAddressRequests()
      .then(in: context) { self.handleFulfilledInvitations(responses: $0, in: context) }
  }

  private func handleFulfilledInvitations(
    responses: [PendingInvitationData],
    in context: NSManagedObjectContext
    ) -> Promise<[PendingInvitationData]> {

    //    UIApplication.shared.applicationIconBadgeNumber = responses.count

    let sortedResponses = responses.sorted(by: { (lhs: PendingInvitationData, rhs: PendingInvitationData) -> Bool in

      let lhsFailedAt = lhs.failedToSendAt ?? .distantPast
      let rhsFailedAt = rhs.failedToSendAt ?? .distantPast

      // The oldest failedToSendAt date should be first, to rotate through them in case of broadcast failure
      // If both are nil (.distantPast), order doesn't matter
      return lhsFailedAt < rhsFailedAt
    })

    guard let firstResponse = sortedResponses.first else {
      return Promise { $0.fulfill([]) }
    }

    var fulfillPromise: Promise<[PendingInvitationData]>!

    context.performAndWait {
      fulfillPromise = when(fulfilled: [self.fulfillInvitationRequest(with: firstResponse, in: context)])
    }

    return fulfillPromise
  }

  private func ensureLocalServerAddressParity(
    with responses: [WalletAddressResponse],
    in context: NSManagedObjectContext) -> Promise<[CKMServerAddress]> {

    return Promise { seal in

      // Delete any local server addresses that are not on the server.
      let remoteAddressIds = responses.compactMap { $0.address }
      let staleServerAddresses = CKMServerAddress.find(notMatchingAddressIds: remoteAddressIds, in: context)
      staleServerAddresses.forEach { context.delete($0) }

      // We assume that the server doesn't have any addresses that are not accounted for in local ServerAddress objects.
      // To handle that we would need to also create a DerivativePath object for that address.

      let allServerAddresses = CKMServerAddress.findAll(in: context)

      seal.fulfill(allServerAddresses)
    }
  }

  private func deleteAddressesFromServer(_ addressIds: [String]) -> Promise<[String]> {
    let deletionPromises = addressIds.map { self.networkManager.deleteWalletAddress($0) }
    return when(fulfilled: deletionPromises) //expects that an empty array of deletionPromises will be fulfilled immediately
      .then {
        return Promise.value(addressIds)
    }
  }

  private func deleteUsedAddresses(allServerAddresses: [CKMServerAddress], in context: NSManagedObjectContext) -> Promise<Int> {
    // Server addresses that have a corresponding Address object with the same address ID
    let usedServerAddresses = allServerAddresses.filter { CKMAddress.find(withAddress: $0.address, in: context) != nil }

    let totalOnServer = allServerAddresses.count
    let totalDesired = self.targetWalletAddressCount

    // Check that totalOnServer matches totalDesired in case we increase it in the future.
    if usedServerAddresses.isEmpty && totalOnServer >= totalDesired {
      return Promise { $0.fulfill(0) }
    }

    let usedAddressIds = usedServerAddresses.map { $0.address }

    return self.deleteAddressesFromServer(usedAddressIds)
      .get(in: context) { _ in
        usedServerAddresses.forEach { context.delete($0) }
        self.persistenceManager.updateWalletLastIndexes(in: context)
      }
      .map { deletedAddressIds -> Int in
        os_log("Deleted addresses from server:", log: self.logger, type: .debug)
        deletedAddressIds.forEach { os_log("\t%{private}@", log: self.logger, type: .debug, $0) }

        // Use the successful deletionResponses to calculate the number of replacement addresses needed
        let remainingOnServer = totalOnServer - deletedAddressIds.count
        let replacementsNeeded = max(0, (totalDesired - remainingOnServer))
        return replacementsNeeded
    }
  }

  /**
   This fulfills the necessary requests then returns an array matching the
   initial responses parameter that has been updated with the posted addresses.
   */
  private func mapAndFulfillAddressRequests(with responses: [WalletAddressRequestResponse],
                                            in context: NSManagedObjectContext) -> Promise<[WalletAddressRequestResponse]> {

    // Split the responses into two groups so that they can be recombined for persistence later
    var unfulfilledRequestResponses: [WalletAddressRequestResponse] = []
    var otherResponses: [WalletAddressRequestResponse] = []
    for res in responses {
      if (res.address ?? "").isEmpty && res.statusCase == .new {
        unfulfilledRequestResponses.append(res)
      } else {
        otherResponses.append(res)
      }
    }

    // Get the next addresses and update the responses with them so that those responses
    // can be used to update the server and update persistence with the address

    let dataSource = walletManager.createAddressDataSource()
    let nextMetaAddresses = dataSource.nextAvailableReceiveAddresses(number: unfulfilledRequestResponses.count,
                                                                     forServerPool: false,
                                                                     indicesToSkip: [],
                                                                     in: context)
    let nextAddressesWithPubKeys: [MetaAddress] = nextMetaAddresses.compactMap { MetaAddress(cnbMetaAddress: $0) }
    guard unfulfilledRequestResponses.count == nextAddressesWithPubKeys.count else {
      return Promise { $0.reject(CKPersistenceError.missingValue(key: "CNBMetaAddress.uncompressedPublicKey")) }
    }

    var responsesWithAddresses: [WalletAddressRequestResponse] = []
    var requestBodies: [AddWalletAddressBody] = []
    for (i, response) in unfulfilledRequestResponses.enumerated() {
      let item = nextAddressesWithPubKeys[i]

      let modifiedRequest = response.copy(withAddress: item.address) // need to include addressPubKey here when added to WalletAddressRequestResponse
      responsesWithAddresses.append(modifiedRequest)

      let body = AddWalletAddressBody(address: item.address, addressPubkey: item.addressPubKey, walletAddressRequestId: response.id)
      requestBodies.append(body)
    }

    // Need to add the addresses to the server and return an array of responses with the newly added addresses
    let updatedResponses = responsesWithAddresses + otherResponses

    return self.fulfillAddressRequests(with: requestBodies, in: context)
      .then { _ in Promise { $0.fulfill(updatedResponses) }}
  }

  /// Because this uses when(fulfilled:), all addWalletAddress calls must succeed for the next promise to execute
  private func fulfillAddressRequests(with bodies: [AddWalletAddressBody], in context: NSManagedObjectContext) -> Promise<[WalletAddressResponse]> {
    return when(fulfilled: bodies.map { body in
      self.networkManager.addWalletAddress(body: body)
        .get { _ in self.analyticsManager.track(event: .dropbitAddressProvided, with: nil) }
    })
  }

  /// This will ignore the status of the passed in responses and persist the status as .addressSent
  private func persistReceivedAddressRequests(_ responses: [WalletAddressRequestResponse], in context: NSManagedObjectContext) {
    responses.forEach {
      let invitation = CKMInvitation.updateOrCreate(withAddressRequestResponse: $0, side: .received, kit: self.phoneNumberKit, in: context)
      invitation.transaction?.isIncoming = true
    }
  }

  /// Promise to fulfill an invitation request. This will broadcast the transaction with provided amount and fee,
  ///   tell the network manager to update the invitation (aka wallet address request) with completed status and txid,
  ///   persist a temporary transaction if needed, and clear the pending invitation data from UserDefaults.
  ///
  /// - Parameters:
  ///   - pendingInvitationData: A copy of the local PendingInvitationData object representing a pending invitation. If this has an address property,
  ///     the transaction will be fulfilled.
  ///   - context: NSManagedObjectContext within which any managed objects will be used. This should be called using `perform` by the caller
  /// - Returns: A Promise containing a PendingInvitationData object upon successfully processing.

  // swiftlint:disable cyclomatic_complexity
  private func fulfillInvitationRequest(
    with pendingInvitationData: PendingInvitationData,
    in context: NSManagedObjectContext
    ) -> Promise<PendingInvitationData> {

    guard let address = pendingInvitationData.address else {
      return Promise(error: PendingInvitationError.noAddressProvided)
    }

    var maybeInvitation: CKMInvitation?
    context.performAndWait {
      maybeInvitation = CKMInvitation.find(withId: pendingInvitationData.id, in: context)
    }
    guard let pendingInvitation = maybeInvitation,
      pendingInvitation.isFulfillable else {
        return Promise(error: PendingInvitationError.noSentInvitationExistsForID)
    }

    let sharedPayloadDTO = self.sharedPayload(invitation: pendingInvitation, pendingInvitationData: pendingInvitationData)

    // create outgoing dto object
    let outgoingTransactionData = OutgoingTransactionData(
      txid: "",
      contactName: pendingInvitationData.name ?? "",
      contactPhoneNumber: pendingInvitationData.phoneNumber,
      contactPhoneNumberHash: pendingInvitation.counterpartyPhoneNumber?.phoneNumberHash ?? "",
      destinationAddress: address,
      amount: pendingInvitationData.btcAmount,
      feeAmount: pendingInvitationData.feeAmount,
      sentToSelf: false,
      requiredFeeRate: nil,
      sharedPayloadDTO: sharedPayloadDTO
    )

    let dto = WalletAddressRequestResponseDTO()

    let tempAddress = "32D9RGK8qVaLMgaEEThfRGjXEmJDQWxLn1"
    return self.networkManager.fetchTransactionSummaries(for: tempAddress)
      .then { (summaryResponses: [AddressTransactionSummaryResponse]) -> Promise<PendingInvitationData> in
        // guard against already funded
        let maybeFound = summaryResponses.first { $0.vout == pendingInvitationData.btcAmount }
        if let found = maybeFound {
          let txid = found.txid
          return self.completeWalletAddressRequestFulfillmentLocally(
            with: dto,
            outgoingTransactionData: outgoingTransactionData,
            txid: txid,
            pendingInvitationData: pendingInvitationData,
            pendingInvitation: pendingInvitation,
            in: context
          )
        } else {
          return Promise { seal in

            // guard against insufficient funds
            var spendableBalance = 0
            context.performAndWait {
              spendableBalance = self.walletManager.spendableBalance(in: context)
            }
            guard spendableBalance >= pendingInvitation.totalPendingAmount else {
              seal.reject(PendingInvitationError.insufficientFundsForInvitationWithID(pendingInvitationData.id))
              return
            }

            self.walletManager.transactionData(forPayment: pendingInvitationData.btcAmount, to: address, withFlatFee: pendingInvitationData.feeAmount)
              .get { dto.transactionData = $0 }
              .then { self.networkManager.broadcastTx(with: $0) }
              .then { (txid: String) -> Promise<PendingInvitationData> in
                self.completeWalletAddressRequestFulfillmentLocally(
                  with: dto,
                  outgoingTransactionData: outgoingTransactionData,
                  txid: txid,
                  pendingInvitationData: pendingInvitationData,
                  pendingInvitation: pendingInvitation,
                  in: context
                )
              }
              .catch { error in
                // Don't mark the PendingInvitationData as failed to broadcast in this scenario, don't want to accidentally double-send
                if error is MoyaError {
                  seal.reject(error)
                  return
                }

                self.persistenceManager.userDefaultsManager.setPendingInvitationFailed(pendingInvitationData)

                if let txDataError = error as? TransactionDataError {
                  switch txDataError {
                  case .insufficientFunds: seal.reject(PendingInvitationError.insufficientFundsForInvitationWithID(pendingInvitationData.id))
                  case .insufficientFee:
                    seal.reject(PendingInvitationError.insufficientFeeForInvitationWithID(pendingInvitationData.id))
                  }
                  return
                }

                let nsError = error as NSError
                let errorCode = TransactionBroadcastError(errorCode: nsError.code)
                switch errorCode {
                case .broadcastTimedOut:
                  seal.reject(TransactionBroadcastError.broadcastTimedOut)
                case .networkUnreachable:
                  seal.reject(TransactionBroadcastError.networkUnreachable)
                case .unknown:
                  seal.reject(TransactionBroadcastError.unknown)
                case .insufficientFee:
                  seal.reject(PendingInvitationError.insufficientFeeForInvitationWithID(pendingInvitationData.id))
                }
            }
          }
        }
    }
  }

  private func completeWalletAddressRequestFulfillmentLocally(
    with dto: WalletAddressRequestResponseDTO,
    outgoingTransactionData: OutgoingTransactionData,
    txid: String,
    pendingInvitationData: PendingInvitationData,
    pendingInvitation: CKMInvitation,
    in context: NSManagedObjectContext) -> Promise<PendingInvitationData> {

    return self.networkManager.postSharedPayloadIfAppropriate(withOutgoingTxData: outgoingTransactionData.copy(withTxid: txid),
                                                              walletManager: self.walletManager)
      .get { dto.txid = $0 }
      .get(in: context) { (txid: String) in
        guard let transactionData = dto.transactionData else {
          let key = WalletAddressRequestResponseDTOKey.transactionData
          throw CKNetworkError.responseMissingValue(keyPath: key.path) }
        self.persistenceManager.persistTemporaryTransaction(
          from: transactionData,
          with: outgoingTransactionData,
          txid: txid,
          invitation: pendingInvitation,
          in: context)

        if pendingInvitation.status == .completed {
          self.analyticsManager.track(event: .dropbitCompleted, with: nil)
        }

      }
      .get { _ in self.persistenceManager.removePendingInvitationData(with: pendingInvitationData.id) }
      .then { (txid: String) -> Promise<WalletAddressRequestResponse> in
        let request = WalletAddressRequest(walletAddressRequestStatus: .completed, txid: txid)
        return self.networkManager.updateWalletAddressRequest(for: pendingInvitationData.id, with: request)
      }
      .then { _ in
        return Promise.value(pendingInvitationData)
    }
  }

  private func sharedPayload(invitation: CKMInvitation, pendingInvitationData: PendingInvitationData) -> SharedPayloadDTO {
    if let ckmPayload = invitation.transaction?.sharedPayload,
      let fiatCode = CurrencyCode(rawValue: ckmPayload.fiatCurrency),
      let pubKey = pendingInvitationData.addressPubKey {
      let amountInfo = SharedPayloadAmountInfo(fiatCurrency: fiatCode, fiatAmount: ckmPayload.fiatAmount)
      return SharedPayloadDTO(addressPubKeyState: .known(pubKey),
                              sharingDesired: ckmPayload.sharingDesired,
                              memo: pendingInvitationData.memo,
                              amountInfo: amountInfo)

    } else {
      return SharedPayloadDTO(addressPubKeyState: .none, sharingDesired: false, memo: pendingInvitationData.memo, amountInfo: nil)
    }
  }

}
