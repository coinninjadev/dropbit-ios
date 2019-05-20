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
    let walletCopy = wmgr.createWalletCopy()
    let transactionBuilder = CNBTransactionBuilder()
    let metadata = transactionBuilder.generateTxMetadata(with: transactionData, wallet: walletCopy)
    let blockchainInfoPromise = blockchainInfoProvider.broadcastTransaction(with: metadata)
    let blockstreamPromise = blockstreamProvider.broadcastTransaction(with: metadata)
    let promises = [
      blockchainInfoPromise,
      blockstreamPromise
    ]

    return when(resolved: promises)
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

  func postSharedPayloadIfAppropriate(withOutgoingTxData outgoingTxData: OutgoingTransactionData,
                                      walletManager: WalletManagerType) -> Promise<String> {
    guard let sharedPayloadDTO = outgoingTxData.sharedPayloadDTO,
      case let .known(addressPubKey) = sharedPayloadDTO.addressPubKeyState else {
      return Promise.value(outgoingTxData.txid)
    }

    switch outgoingTxData.dropBitType {
    case .none: return Promise(error: CKPersistenceError.missingValue(key: "identity"))
    default: break
    }

    guard let amountInfo = sharedPayloadDTO.amountInfo else {
      return Promise(error: CKPersistenceError.missingValue(key: "amountInfo"))
    }

    let payload = SharedPayloadV2(txid: outgoingTxData.txid,
                                  memo: sharedPayloadDTO.memo,
                                  amountInfo: amountInfo,
                                  dropBitType: outgoingTxData.dropBitType)
    return walletManager.encryptPayload(payload, addressPubKey: addressPubKey)
      .then { encryptedPayload -> Promise<Void> in
        let sharingObservantPayload = sharedPayloadDTO.shouldShare ? encryptedPayload : ""
        let body = CreateTransactionNotificationBody(txid: outgoingTxData.txid,
                                                     address: outgoingTxData.destinationAddress,
                                                     identityHash: outgoingTxData.identityHash,
                                                     encryptedPayload: sharingObservantPayload,
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
