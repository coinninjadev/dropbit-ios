//
//  NetworkManager+TransactionBroadcastable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import PromiseKit

protocol TransactionBroadcastable: AnyObject {
  /// Broadcast Transaction with provided data.
  ///
  /// - Parameter transactionData: Object describing the transaction to be broadcast.
  /// - Returns: A Promise of a String, which is the `txid` in the event of a successful broadcast.
  func broadcastTx(with transactionData: CNBTransactionData) -> Promise<String>
  func broadcastTx(metadata: CNBTransactionMetadata) -> Promise<String>

  func postSharedPayloadIfAppropriate(withOutgoingTxData outgoingTxData: OutgoingTransactionData, walletManager: WalletManagerType) -> Promise<String>

}

struct BroadcastInfo: Error {

  struct Encoded {
    let statusCode: String
    let statusMessage: String
  }

  enum Destination {
    case bci(Encoded)
    case blockstream(Encoded)
  }

  init(destination: Destination) {
    self.destination = destination
  }

  var txid: String?
  var destination: Destination
}

extension NetworkManager: TransactionBroadcastable {

  func broadcastTx(with transactionData: CNBTransactionData) -> Promise<String> {
    guard let wmgr = walletDelegate?.mainWalletManager() else { return Promise(error: CKPersistenceError.noWalletWords) }
    let wallet = wmgr.wallet
    let transactionBuilder = CNBTransactionBuilder()
    let txMetadata = transactionBuilder.generateTxMetadata(with: transactionData, wallet: wallet)

    return broadcastTx(metadata: txMetadata)
  }

  func broadcastTx(metadata: CNBTransactionMetadata) -> Promise<String> {

    #if DEBUG
      return broadcastRegtestTx(with: metadata)
    #else
      return broadcastMainnetTx(with: metadata)
    #endif
  }

  private func broadcastMainnetTx(with txMetadata: CNBTransactionMetadata) -> Promise<String> {
    return when(resolved: [blockchainInfoProvider.broadcastTransaction(with: txMetadata),
                           blockstreamProvider.broadcastTransaction(with: txMetadata)])
      .then { [weak self] (results: [PromiseKit.Result<BroadcastInfo>]) -> Promise<String> in
        var success = false
        var txid = ""
        var returnError: Error!
        var analyticEvents: [AnalyticsEventValue] = []
        for result in results {
          switch result {
          case .fulfilled(let value):
            success = success || true
            txid = value.txid ?? ""

            switch value.destination {
            case .bci(let encoded):
              analyticEvents.append(AnalyticsEventValue(key: .blockChainInfoCode, value: String(describing: encoded.statusCode)))
              analyticEvents.append(AnalyticsEventValue(key: .blockChainInfoMessage, value: encoded.statusMessage))
            case .blockstream(let encoded):
              analyticEvents.append(AnalyticsEventValue(key: .blockstreamInfoCode, value: String(describing: encoded.statusCode)))
              analyticEvents.append(AnalyticsEventValue(key: .blockstreamInfoMessage, value: encoded.statusMessage))
            }
          case .rejected(let error):
            success = success || false
            returnError = error

            if let error = error as? BroadcastInfo {
              switch error.destination {
              case .bci(let encoded):
                analyticEvents.append(AnalyticsEventValue(key: .blockChainInfoCode, value: String(describing: encoded.statusCode)))
                analyticEvents.append(AnalyticsEventValue(key: .blockChainInfoMessage, value: encoded.statusMessage))
              case .blockstream(let encoded):
                analyticEvents.append(AnalyticsEventValue(key: .blockstreamInfoCode, value: String(describing: encoded.statusCode)))
                analyticEvents.append(AnalyticsEventValue(key: .blockstreamInfoMessage, value: encoded.statusMessage))
              }
            }
          }
        }

        if success {
          self?.analyticsManager.track(event: .successBroadcastTransaction, with: analyticEvents)
          return Promise.value(txid)
        } else {
          self?.analyticsManager.track(event: .paymentSentFailed, with: analyticEvents)
          return Promise(error: returnError)
        }
    }
  }

  private func broadcastRegtestTx(with transactionMetadata: CNBTransactionMetadata) -> Promise<String> {
    return cnProvider.requestVoid(BroadcastTarget.sendRawTransaction(transactionMetadata.encodedTx))
      .map { _ in return transactionMetadata.txid }
  }

  func postSharedPayloadIfAppropriate(withOutgoingTxData outgoingTxData: OutgoingTransactionData,
                                      walletManager: WalletManagerType) -> Promise<String> {
    guard let sharedPayloadDTO = outgoingTxData.sharedPayloadDTO,
      case let .known(addressPubKey) = sharedPayloadDTO.addressPubKeyState,
      let senderIdentityBody = outgoingTxData.sharedPayloadSenderIdentity else {
        //Skip posting payload and just return the txid
        return Promise.value(outgoingTxData.txid)
    }

    switch outgoingTxData.dropBitType {
    case .none: return Promise(error: CKPersistenceError.missingValue(key: "outgoingTxData.dropBitType"))
    default: break
    }

    guard let amountInfo = sharedPayloadDTO.amountInfo else {
      return Promise(error: CKPersistenceError.missingValue(key: "amountInfo"))
    }

    let sharingObservantMemo = sharedPayloadDTO.shouldShare ? (sharedPayloadDTO.memo ?? "") : ""
    let payload = SharedPayloadV2(txid: outgoingTxData.txid,
                                  memo: sharingObservantMemo,
                                  amountInfo: amountInfo,
                                  senderIdentity: senderIdentityBody)
    return walletManager.encryptPayload(payload, addressPubKey: addressPubKey)
      .then { encryptedPayload -> Promise<Void> in
        let body = CreateTransactionNotificationBody(txid: outgoingTxData.txid,
                                                     address: outgoingTxData.destinationAddress,
                                                     identityHash: outgoingTxData.identityHash,
                                                     encryptedPayload: encryptedPayload,
                                                     encryptedFormat: "1")
        return self.addTransactionNotification(body: body)
      }
      .get {
        // Logs an event for all outgoing DropBits, event value is false if sharing turned off
        let stringValue = sharedPayloadDTO.shouldShare.description
        let eventValue = AnalyticsEventValue(key: .sharingEnabled, value: stringValue)
        self.analyticsManager.track(event: .sharedPayloadSent, with: eventValue)
      }
      .then { Promise.value(outgoingTxData.txid) }
  }

}
