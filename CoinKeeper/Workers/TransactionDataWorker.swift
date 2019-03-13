//
//  TransactionDataWorker.swift
//  CoinKeeper
//
//  Created by BJ Miller on 5/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
import CoreData
import CNBitcoinKit
import os.log
import PhoneNumberKit

protocol TransactionDataWorkerType: AnyObject {

  /**
   Gets updates from the network and updates the context, but does not save
   the context so that inserted Addresses can be identified.
   */

  /// Perform sync routine of fetching all transactions related to the default wallet.
  ///
  /// - Parameter context: a managed object context within which to work.
  /// - Returns: the result of performFetchAndStoreAllTransactionalData(in:force:), where `force` is false.
  func performFetchAndStoreAllTransactionalData(in context: NSManagedObjectContext) -> Promise<Void>

  /// Perform sync routine of fetching all transactions related to the default wallet.
  ///
  /// - Parameters:
  ///   - context: a managed object context within which to work.
  ///   - fullSync: whether the routine should force overwrite local persisted data with what is fetched from API.
  /// - Returns: a Promise<Void>
  func performFetchAndStoreAllTransactionalData(in context: NSManagedObjectContext, fullSync: Bool) -> Promise<Void>

}

class TransactionDataWorker: TransactionDataWorkerType {

  let walletManager: WalletManagerType
  let persistenceManager: PersistenceManagerType
  let networkManager: NetworkManagerType
  let analyticsManager: AnalyticsManagerType

  let phoneNumberKit = PhoneNumberKit()

  private let gapLimit = 20
  private let logger = OSLog(subsystem: "com.coinninja.transactionDataWorker", category: "aggregate_tx_responses")

  init(
    walletManager: WalletManagerType,
    persistenceManager: PersistenceManagerType,
    networkManager: NetworkManagerType,
    analyticsManager: AnalyticsManagerType
    ) {
    self.walletManager = walletManager
    self.persistenceManager = persistenceManager
    self.networkManager = networkManager
    self.analyticsManager = analyticsManager
  }

  func performFetchAndStoreAllTransactionalData(in context: NSManagedObjectContext) -> Promise<Void> {
    return self.performFetchAndStoreAllTransactionalData(in: context, fullSync: false)
  }

  func performFetchAndStoreAllTransactionalData(in context: NSManagedObjectContext, fullSync: Bool) -> Promise<Void> {
    CKNotificationCenter.publish(key: .didStartSync, object: nil, userInfo: nil)

    let receiveAddressFetcher: (Int) -> CNBMetaAddress = { [unowned self] in self.walletManager.createAddressDataSource().receiveAddress(at: $0) }
    let changeAddressFetcher: (Int) -> CNBMetaAddress = { [unowned self] in self.walletManager.createAddressDataSource().changeAddress(at: $0) }
    let minimumSeekReceiveIndex: Int? = self.minimumSeekReceiveAddressIndex(in: context)

    if fullSync {
      return fetchAddressTransactionSummaries(seekingThroughIndex: minimumSeekReceiveIndex, in: context, addressFetcher: receiveAddressFetcher)
        .then(in: context) { self.fetchAddressTransactionSummaries(in: context, aggregatingATSResponses: $0, addressFetcher: changeAddressFetcher) }
        .then(in: context) { self.processAddressTransactionSummaries($0, fullSync: fullSync, in: context) }
    } else {

      // get date of last transaction, minus 1 hour
      // get last receive index and create batches of 20 addresses in advance
      // for each batch, pass the addresses with the date into an optional minDate parameter on networkManager.fetchTransactionSummaries()
      return Promise.value(())
    }
  }

  private func processAddressTransactionSummaries(_ aggregateATSResponse: [AddressTransactionSummaryResponse],
                                                  fullSync: Bool,
                                                  in context: NSManagedObjectContext) -> Promise<Void> {

    let highPriorityBackgroundQueue = DispatchQueue.global(qos: .userInitiated)

    return self.persistAddressTransactionSummaries(with: aggregateATSResponse, in: context)
      .get(in: context) { _ in self.persistenceManager.updateWalletLastIndexes(in: context) }
      .then { Promise.value(TransactionDataWorkerDTO(atsResponses: $0)) }
      .then { (dto: TransactionDataWorkerDTO) -> Promise<TransactionDataWorkerDTO> in
        return self.networkManager.updateCachedMetadata()
          .then { Promise.value(TransactionDataWorkerDTO(checkinResponse: $0).merged(with: dto)) }
      }
      .then(in: context) { (dto: TransactionDataWorkerDTO) -> Promise<TransactionDataWorkerDTO> in
        let txidsToSubtract: Set<String> = (fullSync) ? [] : CKMTransaction.findAllTxidsFullyConfirmed(in: context).asSet()
        let txidsToFetch = dto.txids.asSet().subtracting(txidsToSubtract).asArray()
        return self.promisesForFetchingTransactionDetails(withTxids: txidsToFetch, in: context)
          .then(on: highPriorityBackgroundQueue, in: context) { self.processTransactionResponses($0, in: context) }
          .then { Promise.value(TransactionDataWorkerDTO(txResponses: $0).merged(with: dto)) }
          .then { self.fetchAndMergeTransactionNotifications(dto: $0) }
      }
      .then(in: context) { (dto: TransactionDataWorkerDTO) -> Promise<TransactionDataWorkerDTO> in
        return self.persistAndGroomTransactions(with: dto, in: context, fullSync: fullSync)
          .then { Promise.value(TransactionDataWorkerDTO(txResponses: $0).merged(with: dto)) }
      }
      .then(in: context) { _ in self.updateSpendableBalance(in: context) }
      .then(in: context) { _ in self.updateTransactionDayAveragePrices(in: context) }
  }

  private func fetchAndMergeTransactionNotifications(dto: TransactionDataWorkerDTO) -> Promise<TransactionDataWorkerDTO> {
    let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
    let relevantTxids = dto.txResponses.filter { ($0.date ?? Date()) > fourteenDaysAgo }.map { $0.txid }
    let txNotificationPromises = relevantTxids.map { self.networkManager.fetchTransactionNotifications(forTxid: $0) }
    return when(fulfilled: txNotificationPromises).flatMapValues { $0 }
      .then { responses -> Promise<TransactionDataWorkerDTO> in
        let combinedDTO = TransactionDataWorkerDTO(txNotificationResponses: responses).merged(with: dto)
        return Promise.value(combinedDTO)
    }
  }

  private func minimumSeekReceiveAddressIndex(in context: NSManagedObjectContext) -> Int? {
    var potentialIndices: Set<Int?> = []
    potentialIndices.insert(CKMServerAddress.maxIndex(in: context))
    potentialIndices.insert(persistenceManager.lastReceiveAddressIndex(in: context))

    let validIndices = potentialIndices.compactMap { $0 }.filter { $0 > 0 }
    return validIndices.max()
  }

  private func processTransactionResponses(_ responses: [TransactionResponse], in context: NSManagedObjectContext) -> Promise<[TransactionResponse]> {
    return Promise { seal in
      let results = responses.map { response -> TransactionResponse in
        // any changes to this method should also change CKMTransaction's calculateIsSentToSelf calculation
        var copy = response
        let dataSource = self.walletManager.createAddressDataSource()

        let allVoutAddresses = response.voutResponses.flatMap { $0.addresses }
        let ownedVoutAddresses = allVoutAddresses
          .compactMap { dataSource.checkAddressExists(for: $0, in: context) }
          .compactMap { $0.address }

        let vinAddresses = response.vinResponses.flatMap { $0.addresses }
        let numberOfVinsBelongingToWallet = vinAddresses
          .compactMap { dataSource.checkAddressExists(for: $0, in: context) }
          .count

        let isSentToSelf = (allVoutAddresses.count == ownedVoutAddresses.count) && (numberOfVinsBelongingToWallet == vinAddresses.count)

        copy.isSentToSelf = isSentToSelf
        return copy
      }
      seal.fulfill(results)
    }
  }

  private func responsesWithPaths(
    from responses: [AddressTransactionSummaryResponse],
    matching metaAddresses: [CNBMetaAddress]
    ) -> [AddressTransactionSummaryResponse] {

    let addressesInTransactions = Set(responses.map { $0.address })
    let metaAddressesInTransactions = addressesInTransactions.compactMap { addr in metaAddresses.first { $0.address == addr } }
    let responsesWithPaths = responses.map { (response: AddressTransactionSummaryResponse) -> AddressTransactionSummaryResponse in
      let cnbDerivativePath = metaAddressesInTransactions.filter { $0.address == response.address }.first?.derivationPath
      let derivativePath = cnbDerivativePath.map(DerivativePathResponse.init)
      return AddressTransactionSummaryResponse(addressTransactionSummaryResponse: response, derivativePathResponse: derivativePath)
    }
    return responsesWithPaths
  }

  /**
   - parameter seekingThroughIndex: Will continue fetching at least until this index is reached, ignoring empty responses
   */
  private func fetchAddressTransactionSummaries(
    atStartIndex startIndex: Int = 0,
    seekingThroughIndex: Int? = nil,
    in context: NSManagedObjectContext,
    aggregatingATSResponses aggregateATSResponses: [AddressTransactionSummaryResponse] = [],
    addressFetcher: @escaping (Int) -> CNBMetaAddress
    ) -> Promise<[AddressTransactionSummaryResponse]> {

    return Promise { seal in
      let endIndex = startIndex + gapLimit
      let metaAddresses = (startIndex..<endIndex).map { addressFetcher($0) }
      let addresses = metaAddresses.compactMap { $0.address }
      var aggregateATSResponsesCopy = aggregateATSResponses

      networkManager.fetchTransactionSummaries(for: addresses)
        .then(in: context) { (atsResponses: [AddressTransactionSummaryResponse]) -> Promise<[AddressTransactionSummaryResponse]> in
          guard atsResponses.isNotEmpty else { return Promise.value(aggregateATSResponsesCopy) }

          aggregateATSResponsesCopy = aggregateATSResponses +
            (self.responsesWithPaths(from: atsResponses, matching: metaAddresses))

          return self.fetchAddressTransactionSummaries(
            atStartIndex: endIndex,
            seekingThroughIndex: seekingThroughIndex,
            in: context,
            aggregatingATSResponses: aggregateATSResponsesCopy,
            addressFetcher: addressFetcher
          )
        }
        .recover { (error: Error) -> Promise<[AddressTransactionSummaryResponse]> in
          var isEmptyResponseError = false
          if let networkError = error as? CKNetworkError, case .emptyResponse = networkError {
            isEmptyResponseError = true
          }

          let shouldContinueSeeking = (seekingThroughIndex ?? 0) > endIndex

          if isEmptyResponseError && shouldContinueSeeking {
            // ignore empty response and continue seeking through index
            return self.fetchAddressTransactionSummaries(
              atStartIndex: endIndex,
              seekingThroughIndex: seekingThroughIndex,
              in: context,
              aggregatingATSResponses: aggregateATSResponsesCopy,
              addressFetcher: addressFetcher
            )
          } else if isEmptyResponseError {
            /* not really an error, just ensuring no more data returned */
            return Promise.value(aggregateATSResponsesCopy)
          } else {
            os_log("unrecoverable error, %@", log: self.logger, type: .error, error.localizedDescription)
            throw error
          }
        }
        .done { seal.fulfill($0) }
        .catch { error in
          os_log("error at end of ATS chain: %@", log: self.logger, type: .error, error.localizedDescription)
          seal.reject(error)
      }
    }
  }

  private func persistAndGroomTransactions(
    with dto: TransactionDataWorkerDTO,
    in context: NSManagedObjectContext,
    fullSync: Bool
    ) -> Promise<[TransactionResponse]> {

    let uniqueTxResponses = dto.txResponses.uniqued()
    let uniqueTxNotificationResponses = dto.txNotificationResponses.uniqued()
    let expectedTxids = dto.txids
    return persistenceManager.persistTransactions(from: uniqueTxResponses, in: context, relativeToCurrentHeight: dto.blockHeight, fullSync: fullSync)
      .get(in: context) { self.decryptAndPersistSharedPayloads(from: uniqueTxNotificationResponses, in: context) }
      .get(in: context) { self.persistenceManager.deleteTransactions(notIn: expectedTxids, in: context) }
      .then(in: context) { self.groomFailedTransactions(notIn: expectedTxids, in: context) }
      .then { return Promise.value(uniqueTxResponses) }
  }

  private func decryptAndPersistSharedPayloads(from responses: [TransactionNotificationResponse], in context: NSManagedObjectContext) {
    let cryptor = CKCryptor(walletManager: self.walletManager)

    let decryptionInputs = responses.compactMap { res -> (payload: String, address: String)? in
      guard let payload = res.encryptedPayload else { return nil }
      return (payload, res.address)
    }

    let addressDataSource = walletManager.createAddressDataSource()
    let decryptedPayloads: [Data] = decryptionInputs.compactMap { inputs in
      guard addressDataSource.checkAddressExists(for: inputs.address, in: context) != nil else { return nil }
      do {
        let payloadData = try cryptor.decrypt(payloadAsBase64String: inputs.payload, withReceiveAddress: inputs.address, in: context)
        os_log("Successfully decrypted payload", log: self.logger, type: .debug)
        return payloadData
      } catch {
        os_log("Failed to decrypt payload", log: self.logger, type: .error)
        return nil
      }
    }

    // This should succeed in partially decoding future versions if they are purely additive to the schema
    let payloads: [SharedPayloadV1] = decryptedPayloads.compactMap { try? SharedPayloadV1(data: $0) }
    self.persistenceManager.persistReceivedSharedPayloads(payloads, kit: self.phoneNumberKit, in: context)
  }

  func groomFailedTransactions(notIn txids: [String], in context: NSManagedObjectContext) -> Promise<Void> {

    let failureCandidates = CKMTransaction.findAllToFail(notIn: txids, in: context)

    // Only mark transactions as failed if they don't appear on blockchain.info as well
    let failureConfirmationPromises = failureCandidates.map { self.failTransactionIfNotOnBCI($0) }

    return when(resolved: failureConfirmationPromises).then { _ in
      return Promise { $0.fulfill(()) }
    }
  }

  /// Marks the provided transaction as failed if its relevant txid does not appear on blockchain.info
  private func failTransactionIfNotOnBCI(_ tx: CKMTransaction) -> Promise<Void> {
    guard let context = tx.managedObjectContext else { return Promise.value(()) }
    var relevantTxid = ""
    context.performAndWait {
      relevantTxid = tx.invitation?.txid ?? tx.txid
    }
    return self.networkManager.confirmFailedTransaction(with: relevantTxid)
      .get(in: context) { [weak self] didConfirmFailure in
        if didConfirmFailure {
          tx.markAsFailed()

          let voutDebugDesc = tx.temporarySentTransaction?.reservedVouts.map { $0.debugDescription }.joined(separator: "\n") ?? ""
          let analyticsError = "txid: \(tx.txid) :: reserved_vouts: \(voutDebugDesc)"
          let eventValue = AnalyticsEventValue(key: .broadcastFailed, value: analyticsError)

          if tx.invitation == nil {
            self?.analyticsManager.track(event: .failedToBroadcastTransaction, with: eventValue)
          } else {
            if tx.isIncoming {
              self?.analyticsManager.track(event: .failedToReceiveDropbit, with: nil)
            } else {
              self?.analyticsManager.track(event: .failedToSendDropbit, with: eventValue)
            }
          }
        }
      }.asVoid()
  }

  private func persistAddressTransactionSummaries(
    with aggregateATSResponses: [AddressTransactionSummaryResponse],
    in context: NSManagedObjectContext
    ) -> Promise<[AddressTransactionSummaryResponse]> {

    let uniqueATSResponses = aggregateATSResponses.uniqued()
    return persistenceManager.persistTransactionSummaries(from: uniqueATSResponses, in: context)
      .then { return Promise.value(uniqueATSResponses) }
  }

  private func updateTransactionDayAveragePrices(in context: NSManagedObjectContext) -> Promise<Void> {
    return self.persistenceManager.transactionsWithoutDayAveragePrice(in: context)
      .then(in: context) { self.fetchAndSetDayAveragePrices(for: $0, in: context) }
  }

  private func fetchAndSetDayAveragePrices(for transactions: [CKMTransaction], in context: NSManagedObjectContext) -> Promise<Void> {
    var transactionIterator = transactions.makeIterator()
    let promiseIterator = AnyIterator<Promise<Void>> {
      guard let ckmTransaction = transactionIterator.next() else {
        return nil
      }
      return Promise { seal in
        context.performAndWait {
          self.fetchAndSetDayAveragePrice(for: ckmTransaction, in: context)
            .done(in: context) {
              seal.fulfill(())
            }
            .catch { error in
              seal.reject(error)
          }
        }
      }
    }

    return when(fulfilled: promiseIterator, concurrently: 5).asVoid()
  }

  private func fetchAndSetDayAveragePrice(for transaction: CKMTransaction, in context: NSManagedObjectContext) -> Promise<Void> {
    return self.networkManager.fetchDayAveragePrice(for: transaction.txid)
      .recover { error -> Promise<PriceTransactionResponse> in
        if let providerError = error as? CKNetworkError {
          switch providerError {
          case .recordNotFound,
               .unknownServerError:
            let emptyResponse = PriceTransactionResponse(average: 0)
            return Promise.value(emptyResponse)
          default:
            throw providerError
          }

        } else {
          throw error
        }
      }
      .done(in: context) { (response: PriceTransactionResponse) in
        if response.average != 0 { //ignore emptyResponse created above
          transaction.dayAveragePrice = response.averagePrice
        }
    }
  }

  private func updateSpendableBalance(
    in context: NSManagedObjectContext
    ) -> Promise<Void> {
    return Promise { seal in

      // fetch all unspent vouts, these may or may not belong to our wallet (address != nil)
      var unspentVouts: [CKMVout] = []
      do {
        unspentVouts = try CKMVout.findAllUnspent(in: context)
      } catch {
        os_log("SpendableBalanceError.voutFetchFailed in %@. %@.", log: logger, type: .error, #function)
        seal.reject(SpendableBalanceError.voutFetchFailed)
      }

      // for each vout, get its txid and index, and see if there are any vins with the same previousTxid and index
      for vout in unspentVouts {
        guard let txid = vout.transaction?.txid else { continue }

        let vinFetchReqest: NSFetchRequest<CKMVin> = CKMVin.fetchRequest()
        vinFetchReqest.predicate = CKPredicate.Vin.matching(previousTxid: txid, previousVoutIndex: vout.index)
        vinFetchReqest.fetchLimit = 1

        do {
          let matchingVinExists = try context.fetch(vinFetchReqest).first != nil
          vout.isSpent = matchingVinExists
        } catch {
          seal.reject(SpendableBalanceError.vinFetchFailed)
        }
      }

      seal.fulfill(())
    }
  }

  private func promisesForFetchingTransactionDetails(
    withTxids txids: [String],
    in context: NSManagedObjectContext
    ) -> Promise<[TransactionResponse]> {

    guard txids.isNotEmpty else { return Promise.value([]) }
    let chunkSize = 25
    let batchedTxids = txids.chunked(by: chunkSize)

    let promises = batchedTxids.map { self.networkManager.fetchTransactionDetails(for: $0) }
    return when(fulfilled: promises).flatMapValues { $0 }
  }
}
