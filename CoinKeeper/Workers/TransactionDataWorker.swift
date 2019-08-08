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

// swiftlint:disable type_body_length
class TransactionDataWorker: TransactionDataWorkerType {

  let walletManager: WalletManagerType
  let persistenceManager: PersistenceManagerType
  let networkManager: NetworkManagerType
  let analyticsManager: AnalyticsManagerType

  private let gapLimit = 20

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

  typealias AddressFetcher = (Int) -> CNBMetaAddress

  func performFetchAndStoreAllTransactionalData(in context: NSManagedObjectContext, fullSync: Bool) -> Promise<Void> {
    CKNotificationCenter.publish(key: .didStartSync, object: nil, userInfo: nil)

    let addressDataSource = self.walletManager.createAddressDataSource()
    let receiveAddressFetcher: AddressFetcher = { addressDataSource.receiveAddress(at: $0) }
    let changeAddressFetcher: AddressFetcher = { addressDataSource.changeAddress(at: $0) }

    // Check latest CKMAddressTransactionSummary because it always represents an actual transaction
    // Run full sync if latestTransactionDate is nil
    let latestTransactionDate: Date? = CKMAddressTransactionSummary.findLatest(in: context)?.transaction?.date

    if let latestTxDate = latestTransactionDate, !fullSync {
      return performIncrementalFetchAndStore(latestTxDate: latestTxDate,
                                             addressDataSource: addressDataSource,
                                             receiveFetcher: receiveAddressFetcher,
                                             changeFetcher: changeAddressFetcher,
                                             in: context)

    } else {
      // Full Sync (latest transaction is unknown, relies on recursion until empty response is received)
      let minimumSeekReceiveIndex: Int? = self.minimumSeekReceiveAddressIndex(in: context)

      return fetchAddressTransactionSummaries(seekingThroughIndex: minimumSeekReceiveIndex, in: context, addressFetcher: receiveAddressFetcher)
        .then(in: context) { self.fetchAddressTransactionSummaries(in: context, aggregatingATSResponses: $0, addressFetcher: changeAddressFetcher) }
        .then(in: context) { self.processAddressTransactionSummaries($0, fullSync: fullSync, in: context) }
    }
  }

  private func performIncrementalFetchAndStore(latestTxDate: Date,
                                               addressDataSource: AddressDataSourceType,
                                               receiveFetcher: @escaping AddressFetcher,
                                               changeFetcher: @escaping AddressFetcher,
                                               in context: NSManagedObjectContext) -> Promise<Void> {
    let syncStartDate = latestTxDate.addingTimeInterval(-.oneHour)
    let lastReceiveIndex = addressDataSource.lastReceiveIndex(in: context) ?? 0
    let lastChangeIndex = addressDataSource.lastChangeIndex(in: context) ?? 0
    let seekToReceiveIndex = lastReceiveIndex + gapLimit
    let seekToChangeIndex = lastChangeIndex + gapLimit

    // for each batch, pass the addresses with the date into an optional minDate parameter on networkManager.fetchTransactionSummaries()
    return fetchIncrementalAddressTransactionSummaries(minDate: syncStartDate,
                                                       seekingThroughIndex: seekToReceiveIndex,
                                                       in: context,
                                                       addressFetcher: receiveFetcher)
      .then(in: context) { aggregateResponses in
        return self.fetchIncrementalAddressTransactionSummaries(minDate: syncStartDate,
                                                                seekingThroughIndex: seekToChangeIndex,
                                                                in: context,
                                                                aggregatingATSResponses: aggregateResponses,
                                                                addressFetcher: changeFetcher)}
      .then(in: context) { self.processAddressTransactionSummaries($0, fullSync: false, in: context) }
  }

  private func processAddressTransactionSummaries(_ aggregateATSResponses: [AddressTransactionSummaryResponse],
                                                  fullSync: Bool,
                                                  in context: NSManagedObjectContext) -> Promise<Void> {

    let highPriorityBackgroundQueue = DispatchQueue.global(qos: .userInitiated)

    return self.persistAddressTransactionSummaries(with: aggregateATSResponses, in: context)
      .get(in: context) { _ in self.persistenceManager.brokers.wallet.updateWalletLastIndexes(in: context) }
      .then { Promise.value(TransactionDataWorkerDTO(atsResponses: $0)) }
      .then { (dto: TransactionDataWorkerDTO) -> Promise<TransactionDataWorkerDTO> in
        return self.networkManager.updateCachedMetadata()
          .then { Promise.value(TransactionDataWorkerDTO(checkinResponse: $0).merged(with: dto)) }
      }
      .then(in: context) { (dto: TransactionDataWorkerDTO) -> Promise<TransactionDataWorkerDTO> in
        let txidsToSubtract: Set<String> = (fullSync) ? [] : CKMTransaction.findAllTxidsFullyConfirmed(in: context).asSet()
        let txidsToFetch = dto.atsResponsesTxIds.asSet().subtracting(txidsToSubtract).asArray()
        return self.promisesForFetchingTransactionDetails(withTxids: txidsToFetch, in: context)
          .then(on: highPriorityBackgroundQueue, in: context) { self.processTransactionResponses($0, in: context) }
          .then { Promise.value(TransactionDataWorkerDTO(txResponses: $0).merged(with: dto)) }
          .then { self.fetchAndMergeTransactionNotifications(dto: $0) }
      }
      .then(in: context) { (dto: TransactionDataWorkerDTO) -> Promise<TransactionDataWorkerDTO> in
        return self.persistAndGroomTransactions(with: dto, in: context, fullSync: fullSync)
          .then { Promise.value(TransactionDataWorkerDTO(txResponses: $0).merged(with: dto)) }
      }
      .then(in: context) { _ in self.updateUnspentVouts(in: context) }
      .then(in: context) { _ in self.updateTransactionDayAveragePrices(in: context) }
  }

  private func fetchAndMergeTransactionNotifications(dto: TransactionDataWorkerDTO) -> Promise<TransactionDataWorkerDTO> {
    let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
    let relevantTxids = dto.txResponses.filter { ($0.date ?? Date()) > fourteenDaysAgo }.map { $0.txid }

    var txidIterator = relevantTxids.makeIterator()
    let promiseIterator = AnyIterator<Promise<[TransactionNotificationResponse]>> {
      guard let txid = txidIterator.next() else { return nil }
      return self.networkManager.fetchTransactionNotifications(forTxid: txid)
    }

    return when(fulfilled: promiseIterator, concurrently: 5).flatMapValues { $0 } // flatten to single array of TransactionNotificationResponse
      .then { responses -> Promise<TransactionDataWorkerDTO> in
        let combinedDTO = TransactionDataWorkerDTO(txNotificationResponses: responses).merged(with: dto)
        return Promise.value(combinedDTO)
    }
  }

  private func minimumSeekReceiveAddressIndex(in context: NSManagedObjectContext) -> Int? {
    var potentialIndices: Set<Int?> = []
    potentialIndices.insert(CKMServerAddress.maxIndex(in: context))
    potentialIndices.insert(persistenceManager.brokers.wallet.lastReceiveAddressIndex(in: context))

    let validIndices = potentialIndices.compactMap { $0 }.filter { $0 > 0 }
    return validIndices.max()
  }

  private func processTransactionResponses(_ responses: [TransactionResponse], in context: NSManagedObjectContext) -> Promise<[TransactionResponse]> {
    let dataSource = self.walletManager.createAddressDataSource()
    let searchableAddresses = dataSource.receiveAddressesUpToMaxUsed(in: context) +
      dataSource.changeAddressesUpToMaxUsed(in: context)
    return Promise { seal in
      let results = responses.map { response -> TransactionResponse in
        // any changes to this method should also change CKMTransaction's calculateIsSentToSelf calculation
        var copy = response

        let allVoutAddresses = response.voutResponses.flatMap { $0.addresses }
        let ownedVoutAddresses = allVoutAddresses
          .filter { searchableAddresses.contains($0) }

        let vinAddresses = response.vinResponses.flatMap { $0.addresses }
        let numberOfVinsBelongingToWallet = vinAddresses
          .filter { searchableAddresses.contains($0) }
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
    addressFetcher: @escaping AddressFetcher
    ) -> Promise<[AddressTransactionSummaryResponse]> {

    return Promise { seal in
      let endIndex = startIndex + gapLimit
      let metaAddresses = (startIndex..<endIndex).map { addressFetcher($0) }
      let addresses = metaAddresses.compactMap { $0.address }
      var aggregateATSResponsesCopy = aggregateATSResponses

      networkManager.fetchTransactionSummaries(for: addresses, afterDate: nil)
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
            log.error(error, message: "unrecoverable error")
            throw error
          }
        }
        .done { seal.fulfill($0) }
        .catch { error in
          log.error(error, message: nil)
          seal.reject(error)
      }
    }
  }

  private func fetchIncrementalAddressTransactionSummaries(
    minDate: Date,
    seekingThroughIndex: Int,
    in context: NSManagedObjectContext,
    aggregatingATSResponses aggregateATSResponses: [AddressTransactionSummaryResponse] = [],
    addressFetcher: @escaping AddressFetcher
    ) -> Promise<[AddressTransactionSummaryResponse]> {

    let batchedMetaAddresses: [[CNBMetaAddress]] = Array(0...seekingThroughIndex).map(addressFetcher).chunked(by: 20)
    let atsFetchPromises: [Promise<[AddressTransactionSummaryResponse]>] = batchedMetaAddresses.map { metaAddressBatch in
      let addressBatch = metaAddressBatch.compactMap { $0.address }
      return networkManager.fetchTransactionSummaries(for: addressBatch, afterDate: minDate)
        .map { self.responsesWithPaths(from: $0, matching: metaAddressBatch) }
    }

    return when(fulfilled: atsFetchPromises)
      .map { batchedResponses in
        let flattenedResponses = batchedResponses.flatMap { $0 }
        return aggregateATSResponses + flattenedResponses
    }
  }

  private func persistAndGroomTransactions(
    with dto: TransactionDataWorkerDTO,
    in context: NSManagedObjectContext,
    fullSync: Bool
    ) -> Promise<[TransactionResponse]> {

    let uniqueTxResponses = dto.txResponses.uniqued()
    let uniqueTxNotificationResponses = dto.txNotificationResponses.uniqued()
    let localATSTxids = CKMAddressTransactionSummary.findAllTxids(in: context)
    let expectedTxids = localATSTxids + dto.atsResponsesTxIds //combine local ATS txids with incremental ones for full set of valid txids

    return persistenceManager.brokers.transaction.persistTransactions(from: uniqueTxResponses,
                                                                      in: context,
                                                                      relativeToCurrentHeight: dto.blockHeight,
                                                                      fullSync: fullSync)
      .get(in: context) { self.decryptAndPersistSharedPayloads(from: uniqueTxNotificationResponses, in: context) }
      .get(in: context) { self.persistenceManager.brokers.transaction.deleteTransactions(notIn: expectedTxids, in: context) }
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
        log.debug("Successfully decrypted payload")
        return payloadData
      } catch {
        log.error(error, message: "Failed to decrypt payload")
        return nil
      }
    }

    // This should succeed in partially decoding future versions if they are purely additive to the schema
    self.persistenceManager.persistReceivedSharedPayloads(decryptedPayloads, in: context)
  }

  func groomFailedTransactions(notIn txids: [String], in context: NSManagedObjectContext) -> Promise<Void> {
    #if DEBUG
    return Promise.value(()) //skip broadcast failure checking on regtest
    #else
    let failureCandidates = CKMTransaction.findAllToFail(notIn: txids, in: context)

    // Only mark transactions as failed if they don't appear on blockchain.info as well
    let failureConfirmationPromises = failureCandidates.map { self.failTransactionIfNotOnBCI($0) }

    return when(resolved: failureConfirmationPromises).then { _ in
      return Promise { $0.fulfill(()) }
    }
    #endif
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
    persistenceManager.persistTransactionSummaries(from: uniqueATSResponses, in: context)
    return Promise.value(uniqueATSResponses)
  }

  private func updateTransactionDayAveragePrices(in context: NSManagedObjectContext) -> Promise<Void> {
    return self.persistenceManager.brokers.transaction.transactionsWithoutDayAveragePrice(in: context)
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

  private func updateUnspentVouts(
    in context: NSManagedObjectContext
    ) -> Promise<Void> {
    return Promise { seal in
      // fetch all unspent vouts, these may or may not belong to our wallet (address != nil)
      var unspentVouts: [CKMVout] = []
      do {
        unspentVouts = try CKMVout.findAllUnspent(in: context)
      } catch {
        log.error(error, message: nil)
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
    var batchIterator = batchedTxids.makeIterator()
    let promiseIterator = AnyIterator<Promise<[TransactionResponse]>> {
      guard let batch = batchIterator.next() else { return nil }
      return self.networkManager.fetchTransactionDetails(for: batch)
    }
    return when(fulfilled: promiseIterator, concurrently: 5).flatMapValues { $0 }
  }
}
