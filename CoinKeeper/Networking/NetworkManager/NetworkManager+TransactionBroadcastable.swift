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
    case libbitcoin(Encoded)
  }

  init(destination: Destination) {
    self.destination = destination
  }

  var txid: String?
  var destination: Destination
}

extension NetworkManager: TransactionBroadcastable {

  func broadcastTx(with transactionData: CNBTransactionData) -> Promise<String> {
    guard let wmgr = walletDelegate?.mainWalletManager() else { return Promise(error: CKPersistenceError.noWallet) }
    let walletCopy = wmgr.createWalletCopy()
    let transactionBuilder = CNBTransactionBuilder()
    let metadata = transactionBuilder.generateTxMetadata(with: transactionData, wallet: walletCopy)
    let libbitcoinPromise = self.broadcastToLibbitcoin(with: transactionData)
    let blockchainInfoPromise = blockchainInfoProvider.broadcastTransaction(with: metadata)

    return when(resolved: [libbitcoinPromise, blockchainInfoPromise])
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
            case .libbitcoin(let encoded):
              analyticEvents.append(AnalyticsEventValue(key: .libbitcoinCode, value: String(describing: encoded.statusCode)))
              analyticEvents.append(AnalyticsEventValue(key: .libbitcoinMessage, value: encoded.statusMessage))
            }
          case .rejected(let error):
            success = success || false
            returnError = error

            if let error = error as? BroadcastInfo {
              switch error.destination {
              case .bci(let encoded):
                analyticEvents.append(AnalyticsEventValue(key: .blockChainInfoCode, value: String(describing: encoded.statusCode)))
                analyticEvents.append(AnalyticsEventValue(key: .blockChainInfoMessage, value: encoded.statusMessage))
              case .libbitcoin(let encoded):
                analyticEvents.append(AnalyticsEventValue(key: .libbitcoinCode, value: String(describing: encoded.statusCode)))
                analyticEvents.append(AnalyticsEventValue(key: .libbitcoinMessage, value: encoded.statusMessage))
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

  private func broadcastToLibbitcoin(with transactionData: CNBTransactionData) -> Promise<BroadcastInfo> {
    guard let wmgr = walletDelegate?.mainWalletManager() else { return Promise(error: CKPersistenceError.noWallet) }
    let walletCopy = wmgr.createWalletCopy()
    return Promise { seal in
      let transactionBuilder = CNBTransactionBuilder()
      DispatchQueue.global(qos: .background).async {
        transactionBuilder.broadcast(
          with: transactionData,
          wallet: walletCopy,
          success: { (txid: String) in
            var info = BroadcastInfo(destination: .libbitcoin(BroadcastInfo.Encoded(statusCode: "0", statusMessage: "Success")))
            info.txid = txid
            seal.fulfill(info)
        },
          failure: { (error: Error) in
            let nsError = error as NSError
            let errorMessage = nsError.userInfo[kLibbitcoinErrorMessage] as? String ?? ""
            let errorCode = nsError.userInfo[kLibbitcoinErrorCode] as? String ?? ""
            let info = BroadcastInfo(destination: .libbitcoin(BroadcastInfo.Encoded(statusCode: errorCode, statusMessage: errorMessage)))
            seal.reject(info)
        }
        )
      }
    }
  }

  func postSharedPayloadIfAppropriate(withOutgoingTxData outgoingTxData: OutgoingTransactionData,
                                      walletManager: WalletManagerType) -> Promise<String> {
    guard let sharedPayloadDTO = outgoingTxData.sharedPayloadDTO,
      case let .known(addressPubKey) = sharedPayloadDTO.addressPubKeyState else {
      return Promise.value(outgoingTxData.txid)
    }

    guard let senderNumber = self.persistenceManager.verifiedPhoneNumber() else {
      return Promise(error: CKPersistenceError.missingValue(key: "phoneNumber"))
    }

    guard let amountInfo = sharedPayloadDTO.amountInfo else {
      return Promise(error: CKPersistenceError.missingValue(key: "amountInfo"))
    }

    let payload = SharedPayloadV1(txid: outgoingTxData.txid,
                                  memo: sharedPayloadDTO.memo,
                                  amountInfo: amountInfo,
                                  senderPhoneNumber: senderNumber)

    return walletManager.encryptPayload(payload, addressPubKey: addressPubKey)
      .then { encryptedPayload -> Promise<Void> in
        let sharingObservantPayload = sharedPayloadDTO.shouldShare ? encryptedPayload : ""
        let body = CreateTransactionNotificationBody(txid: outgoingTxData.txid,
                                                     address: outgoingTxData.destinationAddress,
                                                     phoneNumberHash: outgoingTxData.contactPhoneNumberHash,
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
