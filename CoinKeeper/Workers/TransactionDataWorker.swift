//
//  TransactionDataWorker.swift
//  DropBit
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
  func performFetchAndStoreAllOnChainTransactions(in context: NSManagedObjectContext) -> Promise<Void>

  /// Perform sync routine of fetching all transactions related to the default wallet.
  ///
  /// - Parameters:
  ///   - context: a managed object context within which to work.
  ///   - fullSync: whether the routine should force overwrite local persisted data with what is fetched from API.
  /// - Returns: a Promise<Void>
  func performFetchAndStoreAllOnChainTransactions(in context: NSManagedObjectContext, fullSync: Bool) -> Promise<Void>

  func performFetchAndStoreAllLightningTransactions(in context: NSManagedObjectContext) -> Promise<Void>

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

  func performFetchAndStoreAllOnChainTransactions(in context: NSManagedObjectContext) -> Promise<Void> {
    return self.performFetchAndStoreAllOnChainTransactions(in: context, fullSync: false)
  }

  typealias AddressFetcher = (Int) -> CNBMetaAddress

  func performFetchAndStoreAllOnChainTransactions(in context: NSManagedObjectContext, fullSync: Bool) -> Promise<Void> {
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

  func performFetchAndStoreAllLightningTransactions(in context: NSManagedObjectContext) -> Promise<Void> {
    guard let wallet = CKMWallet.find(in: context) else {
      return Promise(error: CKPersistenceError.noManagedWallet)
    }

    let lnBroker = self.persistenceManager.brokers.lightning
    return self.networkManager.getLightningLedger()
      .get(in: context) { response in
        ///Run deletion before persisting the ledger so that it doesn't interfere with wallet
        ///entries whose inverse relationships are not set until the context is saved.
        lnBroker.deleteInvalidWalletEntries(in: context)
        lnBroker.deleteInvalidLedgerEntries(in: context)

        self.persistenceManager.brokers.lightning.persistLedgerResponse(response, forWallet: wallet, in: context)
        self.processOnChainLightningTransfers(withLedger: response.ledger, forWallet: wallet, in: context)
      }
      .then(in: context) { response -> Promise<Void> in
        let lightningEntryIds = response.ledger.filter { $0.type == .lightning }.map { $0.cleanedId }
        return self.fetchTransactionNotifications(forIds: lightningEntryIds)
          .get(in: context) { responses in self.decryptAndPersistSharedPayloads(from: responses, ofType: .lightning, in: context) }
          .asVoid()
      }
  }

  private func processOnChainLightningTransfers(withLedger ledgerResults: [LNTransactionResult],
                                                forWallet wallet: CKMWallet,
                                                in context: NSManagedObjectContext) {
    let lightningTransferTxids = ledgerResults.filter { $0.type == .btc }.map { $0.cleanedId }

    //Update CKMTransactions
    let txFetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    //ignore whether the transaction is already marked as a transfer, so that confirmation counts can be provided to the ledger entries
    txFetchRequest.predicate = CKPredicate.Transaction.txidIn(lightningTransferTxids)

    var transactionsToUpdate: [CKMTransaction] = []
    do {
      transactionsToUpdate = try context.fetch(txFetchRequest)
    } catch {
      log.error(error, message: "failed to fetch transactions to mark for lightning transfers")
    }

    var processingFeesById: [String: Int] = [:]
    for result in ledgerResults {
      processingFeesById[result.cleanedId] = result.processingFee
    }

    for tx in transactionsToUpdate {
      tx.isLightningTransfer = true
      tx.dropBitProcessingFee = processingFeesById[tx.txid] ?? 0
    }

    //Update CKMLedgerEntries
    let ledgerEntryFetchRequest: NSFetchRequest<CKMLNLedgerEntry> = CKMLNLedgerEntry.fetchRequest()
    ledgerEntryFetchRequest.predicate = CKPredicate.LedgerEntry.idIn(lightningTransferTxids)

    var ledgerEntriesToUpdate: [CKMLNLedgerEntry] = []
    do {
      ledgerEntriesToUpdate = try context.fetch(ledgerEntryFetchRequest)
    } catch {
      log.error(error, message: "failed to fetch ledger entries to update with confirmations")
    }

    var confirmationsById: [String: Int] = [:]
    for tx in transactionsToUpdate {
      confirmationsById[tx.txid] = tx.confirmations
    }

    for entry in ledgerEntriesToUpdate {
      let entryId = entry.id ?? ""
      entry.onChainConfirmations = confirmationsById[entryId] ?? 0
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

    return self.fetchTransactionNotifications(forIds: relevantTxids)
      .then { responses -> Promise<TransactionDataWorkerDTO> in
        let combinedDTO = TransactionDataWorkerDTO(txNotificationResponses: responses).merged(with: dto)
        return Promise.value(combinedDTO)
    }
  }

  private func fetchTransactionNotifications(forIds ids: [String]) -> Promise<[TransactionNotificationResponse]> {
    var idIterator = ids.makeIterator()
    let promiseIterator = AnyIterator<Promise<[TransactionNotificationResponse]>> {
      guard let id = idIterator.next() else { return nil }
      return self.networkManager.fetchTransactionNotifications(forId: id)
    }
    return when(fulfilled: promiseIterator, concurrently: 5).flatMapValues { $0 } // flatten to single array of TransactionNotificationResponse
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

        let isSentToSelf = (allVoutAddresses.count == ownedVoutAddresses.count)

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
      .get(in: context) { self.decryptAndPersistSharedPayloads(from: uniqueTxNotificationResponses, ofType: .onChain, in: context) }
      .get(in: context) { self.persistenceManager.brokers.transaction.deleteTransactions(notIn: expectedTxids, in: context) }
      .then(in: context) { self.groomFailedTransactions(notIn: expectedTxids, in: context) }
      .then { return Promise.value(uniqueTxResponses) }
  }

  private func decryptAndPersistSharedPayloads(from responses: [TransactionNotificationResponse],
                                               ofType walletTxType: WalletTransactionType,
                                               in context: NSManagedObjectContext) {
    let decryptedPayloads: [Data]
    switch walletTxType {
    case .onChain:
      decryptedPayloads = decryptedOnChainPayloads(from: responses, in: context)
    case .lightning:
      decryptedPayloads = decryptLightningPayloads(from: responses)
    }

    // This should succeed in partially decoding future versions if they are purely additive to the schema
    self.persistenceManager.persistReceivedSharedPayloads(decryptedPayloads, ofType: walletTxType, in: context)
  }

  private func decryptedOnChainPayloads(from responses: [TransactionNotificationResponse],
                                        in context: NSManagedObjectContext) -> [Data] {
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
        log.debug("Successfully decrypted onChain payload")
        return payloadData
      } catch {
        log.error(error, message: "Failed to decrypt onChain payload")
        return nil
      }
    }
    return decryptedPayloads
  }

  private func decryptLightningPayloads(from responses: [TransactionNotificationResponse]) -> [Data] {
    let cryptor = CKCryptor(walletManager: self.walletManager)
    let decryptedPayloads: [Data] = responses.compactMap { response in
      guard let payloadString = response.encryptedPayload else { return nil }
      do {
        let payloadData = try cryptor.decryptWithDefaultPrivateKey(payloadAsBase64String: payloadString)
        log.debug("Successfully decrypted lightning payload")
        return payloadData
      } catch {
        log.error(error, message: "Failed to decrypt lightning payload")
        return nil
      }
    }
    return decryptedPayloads
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
