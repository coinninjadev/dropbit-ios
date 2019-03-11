//
//  CKMTransaction+CoreDataClass.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import os.log
import PhoneNumberKit

typealias IncomingOutgoingTuple = (incoming: Bool, outgoing: Bool)

@objc(CKMTransaction)
public class CKMTransaction: NSManagedObject {

  public override func awakeFromInsert() {
    super.awakeFromInsert()
    setPrimitiveValue("", forKey: #keyPath(CKMTransaction.txid))
    setPrimitiveValue(false, forKey: #keyPath(CKMTransaction.isSentToSelf))
    setPrimitiveValue(false, forKey: #keyPath(CKMTransaction.broadcastFailed))
  }

  static let confirmationThreshold = 1
  static let fullyConfirmedThreshold = 6

  static func findAll(in context: NSManagedObjectContext) -> [CKMTransaction] {
    return transactions(in: context)
  }

  static func findAll(byTxids txids: [String], in context: NSManagedObjectContext) -> [CKMTransaction] {
    let path = #keyPath(CKMTransaction.txid)
    let predicate = NSPredicate(format: "\(path) IN %@", txids)

    return transactions(matching: predicate, in: context)
  }

  static func findAllFailed(in context: NSManagedObjectContext) -> [CKMTransaction] {
    let predicate = CKPredicate.Transaction.broadcastFailed(is: true)
    return transactions(matching: predicate, in: context)
  }

  static let invitationTxidPrefix = "Invitation_"
  static let failedTxidPrefix = "Failed_"

  /// txid does not begin with a prefix (e.g. invitations with placeholder Transaction objects)
  var txidIsActualTxid: Bool {
    let isInviteOrFailed = txid.starts(with: CKMTransaction.invitationTxidPrefix) || txid.starts(with: CKMTransaction.failedTxidPrefix)
    return !isInviteOrFailed
  }

  func setTxid(withInvitation invitation: CKMInvitation) {
    let combinedString = CKMTransaction.invitationTxidPrefix + invitation.id
    self.txid = combinedString
  }

  static func findAllGroomable(in context: NSManagedObjectContext) -> [CKMTransaction] {
    let invitationKeyPath = #keyPath(CKMTransaction.invitation)
    let tempTxKeyPath = #keyPath(CKMTransaction.temporarySentTransaction)
    let invitationPredicate = NSPredicate(format: "\(invitationKeyPath) == nil")
    let tempTxPredicate = NSPredicate(format: "\(tempTxKeyPath) == nil")
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [invitationPredicate, tempTxPredicate])
    return transactions(matching: predicate, in: context)
  }

  /**
   Returns transactions with a valid txid stored locally, that are at least 5 minutes old,
   but do not appear in txids received from API.
   */
  static func findAllToFail(notIn txidsToKeep: [String], in context: NSManagedObjectContext) -> [CKMTransaction] {

    // broadcastedAt or completedAt is older than 5 minutes
    let minimumValidDate = Date().addingTimeInterval(-180)

    let transactionSubpredicates = [CKPredicate.Transaction.broadcastedBefore(minimumValidDate),
                                    CKPredicate.Transaction.txidNotIn(txidsToKeep),
                                    CKPredicate.Transaction.withValidTxid()] // doesn't have invitation prefix

    let failedTransactionPredicate = NSCompoundPredicate(type: .and, subpredicates: transactionSubpredicates)

    let invitationSubpredicates = [CKPredicate.Transaction.invitationCompletedBefore(minimumValidDate),
                                   CKPredicate.Transaction.invitationHasTxid(),
                                   CKPredicate.Transaction.invitationTxidNotIn(txidsToKeep)]

    let failedInvitationPredicate = NSCompoundPredicate(type: .and, subpredicates: invitationSubpredicates)

    let combinedFailedPredicate = NSCompoundPredicate(type: .or, subpredicates: [failedTransactionPredicate,
                                                                                 failedInvitationPredicate])

    // ignore those already marked as failed
    let notYetFailedPredicate = CKPredicate.Transaction.broadcastFailed(is: false)

    let fullPredicate = NSCompoundPredicate(type: .and, subpredicates: [combinedFailedPredicate,
                                                                        notYetFailedPredicate])

    return transactions(matching: fullPredicate, in: context)
  }

  /**
   Returns an array of transactions which were previously marked as broadcastFailed, but are now observed
   to be included in txids seen by the server.
   */
  static func findAllToUnfail(in txidsToKeep: [String], in context: NSManagedObjectContext) -> [CKMTransaction] {
    let failedPredicate = CKPredicate.Transaction.broadcastFailed(is: true)
    let txidPredicate = CKPredicate.Transaction.txidIn(txidsToKeep)
    let fullPredicate = NSCompoundPredicate(type: .and, subpredicates: [failedPredicate,
                                                                        txidPredicate])
    return transactions(matching: fullPredicate, in: context)
  }

  static func findAllToDelete(notIn txidsToKeep: [String], in context: NSManagedObjectContext) -> [CKMTransaction] {
    let unseenTxidPredicate = CKPredicate.Transaction.txidNotIn(txidsToKeep)
    let noTempTxPredicate = CKPredicate.Transaction.withoutTemporaryTransaction()
    let noInvitationPredicate = CKPredicate.Transaction.withoutInvitation()
    let predicate = NSCompoundPredicate(type: .and, subpredicates: [unseenTxidPredicate, noTempTxPredicate, noInvitationPredicate])
    return transactions(matching: predicate, in: context)
  }

  static func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    let withInvitationPredicate = CKPredicate.Transaction.withInvitation()
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.predicate = withInvitationPredicate

    let dropbitInvitation = transactions(with: fetchRequest, in: context).asSet()
    let incoming = dropbitInvitation.filter { $0.isIncoming }
    let outgoing = dropbitInvitation.subtracting(incoming)

    return (incoming: incoming.isNotEmpty, outgoing: outgoing.isNotEmpty)
  }

  static func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    let withInvitationPredicate = CKPredicate.Transaction.withoutInvitation()
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.predicate = withInvitationPredicate

    let regularTransactions = transactions(with: fetchRequest, in: context).asSet()
    let incoming = regularTransactions.filter { $0.isIncoming }
    let outgoing = regularTransactions.subtracting(incoming)

    return (incoming: incoming.isNotEmpty, outgoing: outgoing.isNotEmpty)
  }

  static func findAllTxidsFullyConfirmed(in context: NSManagedObjectContext) -> [String] {
    let confirmationKeyPath = #keyPath(CKMTransaction.confirmations)
    let txidKeyPath = #keyPath(CKMTransaction.txid)
    let predicate = NSPredicate(format: "\(confirmationKeyPath) > %d", fullyConfirmedThreshold)
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.predicate = predicate
    fetchRequest.propertiesToFetch = [txidKeyPath]
    return transactions(with: fetchRequest, in: context).map { $0.txid }
  }

  private static func transactions(matching predicate: NSPredicate, in context: NSManagedObjectContext) -> [CKMTransaction] {
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.predicate = predicate
    return transactions(with: fetchRequest, in: context)
  }

  private static func transactions(with fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest(),
                                   in context: NSManagedObjectContext) -> [CKMTransaction] {
    var result: [CKMTransaction] = []
    context.performAndWait {
      do {
        result = try context.fetch(fetchRequest)
      } catch {
        result = []
      }
    }
    return result
  }

  static func find(byTxid txid: String, in context: NSManagedObjectContext) -> CKMTransaction? {
    let path = #keyPath(CKMTransaction.txid)
    let predicate = NSPredicate(format: "\(path) = %@", txid)
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.predicate = predicate
    fetchRequest.fetchLimit = 1

    var ckmTransaction: CKMTransaction?
    context.performAndWait {
      do {
        ckmTransaction = try context.fetch(fetchRequest).first
      } catch {
        ckmTransaction = nil
      }
    }
    return ckmTransaction
  }

  static func findOrCreate(
    with txResponse: TransactionResponse,
    in context: NSManagedObjectContext,
    relativeToBlockHeight blockHeight: Int,
    fullSync: Bool
    ) -> CKMTransaction {
    var transaction: CKMTransaction!
    context.performAndWait {
      if let foundTx = CKMTransaction.find(byTxid: txResponse.txid, in: context) {
        transaction = foundTx
      } else {
        transaction = CKMTransaction(insertInto: context)
      }
    }
    transaction.configure(with: txResponse, in: context, relativeToBlockHeight: blockHeight, fullSync: fullSync)
    return transaction
  }

  private func removeTemporaryTransactionIfNeeded(in context: NSManagedObjectContext) {
    context.performAndWait {
      temporarySentTransaction.map { context.delete($0) }
    }
  }

  func configure(
    with txResponse: TransactionResponse,
    in context: NSManagedObjectContext,
    relativeToBlockHeight blockHeight: Int,
    fullSync: Bool
    ) {
    context.performAndWait {
      // configure the tx here
      if temporarySentTransaction != nil, txResponse.txid == txid {
        removeTemporaryTransactionIfNeeded(in: context)
      }
      txid = txResponse.txid
      blockHash = txResponse.blockHash
      confirmations = (txResponse.blockHash ?? "").isEmpty ? 0 : txResponse.blockheight.map { (blockHeight - $0) + 1 } ?? 0
      date = txResponse.receivedTime ?? txResponse.date
      sortDate = txResponse.sortDate
      network = "btc://main"

      // vins
      let vinArray = txResponse.vinResponses.map { (vinResponse: TransactionVinResponse) -> CKMVin in
        let vin = CKMVin.findOrCreate(with: vinResponse, in: context, fullSync: fullSync)
        vin.transaction = self
        return vin
      }
      self.vins = Set(vinArray)

      // vouts
      let voutArray = txResponse.voutResponses.compactMap { (voutResponse: TransactionVoutResponse) -> CKMVout? in
        let vout = CKMVout.findOrCreate(with: voutResponse, in: context, fullSync: fullSync)
        vout?.transaction = self
        return vout
      }
      self.vouts = Set(voutArray)

      isIncoming = calculateIsIncoming(in: context)

      let atss = CKMAddressTransactionSummary.find(by: txResponse.txid, in: context)
      addressTransactionSummaries = atss.asSet()
      atss.forEach { $0.transaction = self } // just being extra careful to ensure bi-directional integrity

      if !isIncoming {
        self.isSentToSelf = txResponse.isSentToSelf
      }
    }
  }

  func calculateIsSentToSelf(in context: NSManagedObjectContext) -> Bool {
    // any changes to this method should also change TransactionDataWorker's isSentToSelf calculation

    guard invitation == nil else { return false }

    if let temp = temporarySentTransaction {
      return temp.isSentToSelf
    } else {
      // regular transaction
      let allVoutAddresses = vouts.flatMap { $0.addressIDs }
      let ownedVoutAddresses = allVoutAddresses
        .compactMap { CKMAddress.find(withAddress: $0, in: context) }

      let numberOfVinsBelongingToWallet = vins.filter { $0.belongsToWallet }.count

      let sentToSelf = (numberOfVinsBelongingToWallet == vins.count) && (allVoutAddresses.count == ownedVoutAddresses.count)
      return sentToSelf
    }
  }

  func calculateIsIncoming(in context: NSManagedObjectContext) -> Bool {
    if let invitation = self.invitation {
      return invitation.side == .receiver
    }
    let txReceivedFunds = vouts.compactMap { $0.address }.filter { $0.isReceiveAddress }.isNotEmpty
    let txSentFunds = vins.filter { $0.belongsToWallet }.asArray().isNotEmpty
    return txReceivedFunds && !txSentFunds
  }

  /// Configures a newly created Transaction object with an instance of OutgoingTransactionData DTO.
  ///
  /// - Parameters:
  ///   - outgoingTransactionData: The DTO (data transfer object) which accumulates data about the
  ///     outgoing transaction through the send flow. The included SharedPayloadDTO is ignored by this function.
  ///   - phoneNumber: Optional PhoneNumber. If nil, will attempt to find-or-create by phone number string in
  ///     outgoingTransactionData.
  ///   - context: The NSManagedObjectContext within which this operation will be executed.
  ///     The caller of this method should use `perform` or `performAndWait` and call this method inside that block.
  func configure(with outgoingTransactionData: OutgoingTransactionData, phoneNumber: CKMPhoneNumber? = nil, in context: NSManagedObjectContext) {
    // self.txid should remain as an empty string so that the outgoingTransactionData.txid UUID
    // doesn't trigger a 4xx error when sending txids to the server

    context.performAndWait {
      self.sortDate = Date()
      self.date = self.sortDate
      self.isSentToSelf = outgoingTransactionData.sentToSelf
      self.isIncoming = false
      self.memo = outgoingTransactionData.sharedPayloadDTO?.memo

      if outgoingTransactionData.txid.isNotEmpty {
        self.txid = outgoingTransactionData.txid
      }

      if self.txid.starts(with: CKMTransaction.invitationTxidPrefix) {
        self.txid = outgoingTransactionData.txid
      }

      // counterparty address
      counterpartyAddress = CKMCounterpartyAddress.findOrCreate(withAddress: outgoingTransactionData.destinationAddress, in: context)

      // temporary sent transaction
      let tempTx = temporarySentTransaction ?? CKMTemporarySentTransaction(insertInto: context)
      tempTx.amount = outgoingTransactionData.amount
      tempTx.feeAmount = outgoingTransactionData.feeAmount
      tempTx.isSentToSelf = outgoingTransactionData.sentToSelf
      tempTx.transaction = self

      if let number = phoneNumber {
        number.configure(with: outgoingTransactionData, in: context)
        self.phoneNumber = number

      } else if let contactNumber = outgoingTransactionData.contactPhoneNumber,
        let inputs = ManagedPhoneNumberInputs(phoneNumber: contactNumber) {
        let number = CKMPhoneNumber.findOrCreate(withInputs: inputs,
                                                 phoneNumberHash: outgoingTransactionData.contactPhoneNumberHash,
                                                 in: context)
        number.configure(with: outgoingTransactionData, in: context)
        self.phoneNumber = number
      }
    }
  }

  /// Returns early if this transaction already has a CKMTransactionSharedPayload attached
  func configureNewSenderSharedPayload(with sharedPayloadDTO: SharedPayloadDTO?, in context: NSManagedObjectContext) {
    guard let dto = sharedPayloadDTO else { return }

    self.memo = dto.memo

    guard self.sharedPayload == nil,
      let amountInfo = dto.amountInfo,
      dto.shouldShare //don't persist if not shared
      else { return }

    self.sharedPayload = CKMTransactionSharedPayload(sharingDesired: dto.sharingDesired,
                                                     fiatAmount: amountInfo.fiatAmount,
                                                     fiatCurrency: amountInfo.fiatCurrencyCode.rawValue,
                                                     receivedPayload: nil,
                                                     insertInto: context)
  }

  static let transactionHistorySortDescriptors: [NSSortDescriptor] = [
    NSSortDescriptor(key: #keyPath(CKMTransaction.sortDate), ascending: false)
  ]

  var isCancellable: Bool {
    guard let invite = invitation else { return false }
    let cancellableStatuses: [InvitationStatus] = [.notSent, .requestSent, .addressSent]
    return (!isIncoming && cancellableStatuses.contains(invite.status))
  }

  var isInvite: Bool {
    return invitation != nil
  }

  var isConfirmed: Bool {
    return confirmations >= CKMTransaction.confirmationThreshold
  }

  /// Returns sum of `amount` value from all vins
  var sumVins: Int {
    return vins.reduce(0) { $0 + $1.amount }
  }

  /// Returns sum of `amount` value from all vouts
  var sumVouts: Int {
    return vouts.reduce(0) { $0 + $1.amount }
  }

  /// Returns sent amount from vins, relative to addresses owned by user's wallet
  var myVins: Int {
    return vins.filter { $0.belongsToWallet }.reduce(0) { $0 + $1.amount }
  }

  /// Returns received amount from vouts, relative to addresses owned by user's wallet
  var myVouts: Int {
    return vouts.filter { $0.address != nil }.reduce(0) { $0 + $1.amount }
  }

  /// networkFee is calculated in Satoshis, should be sum(vin) - sum(vout), but only vin/vout pertaining to our addresses
  var networkFee: Int {
    if let tempTransaction = temporarySentTransaction {
      return tempTransaction.feeAmount
    } else if let invitation = invitation {
      switch invitation.status {
      case .requestSent: return invitation.fees
      default: break
      }
    }
    return sumVins - sumVouts
  }

  /// Net effect of the transaction on the wallet of current user, returned in Satoshis
  var netWalletAmount: Int {
    if let tx = temporarySentTransaction {
      return (tx.amount + tx.feeAmount) * -1 // negative, to show an outgoing amount with a negative impact on wallet balance
    }

    if vins.isEmpty && vouts.isEmpty, let invite = invitation { // Incoming invitation without valid transaction
      return invite.btcAmount
    }

    return myVouts - myVins
  }

  /// The amount received after the network fee has been subtracted from the sent amount
  var receivedAmount: Int {
    return isIncoming ? netWalletAmount : (abs(netWalletAmount) - networkFee)
  }

  /// The relevant address belonging to the wallet.
  var walletReceiverAddressId: String? {
    guard isIncoming else { return nil }
    return addressTransactionSummaries.first(where: { $0.isChangeAddress == false })?.addressId
  }

  /// Returns first outgoing vout address, otherwise tx must be sent to self
  var counterpartyReceiverAddressId: String? {
    if isIncoming {
      return invitation?.addressProvidedToSender
    }

    if let addressId = counterpartyAddress?.addressId {
      return addressId
    }

    // ourAddresses are addresses we own by relationship to AddressTransactionSummary objects
    let ourAddressIds = Set(addressTransactionSummaries.compactMap { $0.address?.addressId })

    // firstOutgoing is first vout addressID where ourAddresses doesn't appear in vout's addressIDs
    let firstOutgoing = vouts.compactMap { self.firstVoutAddress(from: Set($0.addressIDs), notMatchingAddresses: ourAddressIds) }.first

    return firstOutgoing
  }

  /// Returns nil if any of our addresses are in vout addresses
  private func firstVoutAddress(from voutAddressIDs: Set<String>, notMatchingAddresses ourAddresses: Set<String>) -> String? {
    return ourAddresses.isDisjoint(with: voutAddressIDs) ? voutAddressIDs.first : nil
  }

}

extension CKMTransaction: CounterpartyRepresentable {

  var counterpartyName: String? {
    if let invite = invitation {
      return invite.counterpartyName
    } else {
      return phoneNumber?.counterparty?.name
    }
  }

  func counterpartyPhoneNumber(deviceCountryCode: Int?, kit: PhoneNumberKit) -> String? {
    guard let relevantPhoneNumber = invitation?.counterpartyPhoneNumber ?? phoneNumber else { return nil }
    let globalPhoneNumber = relevantPhoneNumber.asGlobalPhoneNumber

    var format: PhoneNumberFormat = .international
    if let code = deviceCountryCode {
      format = (code == globalPhoneNumber.countryCode) ? .national : .international
    }
    let formatter = CKPhoneNumberFormatter(kit: kit, format: format)

    return try? formatter.string(from: globalPhoneNumber)
  }

  var counterpartyAddressId: String? {
    return counterpartyReceiverAddressId
  }
}

extension CKMTransaction {
  static func == (lhs: CKMTransaction, rhs: CKMTransaction) -> Bool {
    return lhs.txid == rhs.txid
  }
}
