//
//  NetworkManager+TransactionBroadcastable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Cnlib
import PromiseKit

protocol TransactionBroadcastable: AnyObject {
  /// Broadcast Transaction with provided data.
  ///
  /// - Parameter transactionData: Object describing the transaction to be broadcast.
  /// - Returns: A Promise of a String, which is the `txid` in the event of a successful broadcast.
  func broadcastTx(with transactionData: CNBCnlibTransactionData) -> Promise<String>
  func broadcastTx(metadata: CNBCnlibTransactionMetadata) -> Promise<String>

  func postSharedPayloadIfAppropriate(withPostableObject object: SharedPayloadPostableObject,
                                      walletManager: WalletManagerType) -> Promise<String>

}

struct BroadcastInfo: Error {

  struct Encoded {
    let statusCode: String
    let statusMessage: String
  }

  enum Destination {
    case coinninja(Encoded)
    case blockstream(Encoded)

    var description: String {
      switch self {
      case .coinninja(let encoded):
        return "CoinNinja: \(encoded.statusCode), \(encoded.statusMessage)"
      case .blockstream(let encoded):
        return "Blockstream: \(encoded.statusCode), \(encoded.statusMessage)"
      }
    }
  }

  init(destination: Destination) {
    self.destination = destination
  }

  var txid: String?
  var destination: Destination

  var localizedDescription: String {
    return """
    BroadcastInfo:
      txid: \(txid ?? "-")
      destination: \(destination.description)
    """
  }
}

extension NetworkManager: TransactionBroadcastable {

  func broadcastTx(with transactionData: CNBCnlibTransactionData) -> Promise<String> {
    guard let wmgr = walletDelegate?.mainWalletManager() else { return Promise(error: DBTError.Persistence.noWalletWords) }
    guard transactionData.utxoCount() > 0 else { return Promise(error: DBTError.TransactionData.noSpendableFunds) }
    let wallet = wmgr.wallet
    do {
      let txMetadata = try wallet.buildTransactionMetadata(transactionData)
      return broadcastTx(metadata: txMetadata)
    } catch {
      log.error(error, message: "Failed to generate tx metadata before broadcasting.")
      return Promise(error: error)
    }
  }

  func broadcastTx(metadata: CNBCnlibTransactionMetadata) -> Promise<String> {

    #if DEBUG
    if CKUserDefaults().useRegtest {
      return broadcastRegtestTx(with: metadata)
    } else {
      return broadcastMainnetTx(with: metadata)
    }
    #else
      return broadcastMainnetTx(with: metadata)
    #endif
  }

  private func broadcastMainnetTx(with txMetadata: CNBCnlibTransactionMetadata) -> Promise<String> {
    return when(resolved: [coinNinjaProvider.broadcastTransaction(with: txMetadata),
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
            case .coinninja(let encoded):
              analyticEvents.append(AnalyticsEventValue(key: .coinninjaCode, value: String(describing: encoded.statusCode)))
              analyticEvents.append(AnalyticsEventValue(key: .coinninjaMessage, value: encoded.statusMessage))
            case .blockstream(let encoded):
              analyticEvents.append(AnalyticsEventValue(key: .blockstreamInfoCode, value: String(describing: encoded.statusCode)))
              analyticEvents.append(AnalyticsEventValue(key: .blockstreamInfoMessage, value: encoded.statusMessage))
            }
          case .rejected(let error):
            success = success || false
            returnError = error

            if let error = error as? BroadcastInfo {
              log.error(error.localizedDescription)
              switch error.destination {
              case .coinninja(let encoded):
                analyticEvents.append(AnalyticsEventValue(key: .coinninjaCode, value: String(describing: encoded.statusCode)))
                analyticEvents.append(AnalyticsEventValue(key: .coinninjaMessage, value: encoded.statusMessage))
              case .blockstream(let encoded):
                analyticEvents.append(AnalyticsEventValue(key: .blockstreamInfoCode, value: String(describing: encoded.statusCode)))
                analyticEvents.append(AnalyticsEventValue(key: .blockstreamInfoMessage, value: encoded.statusMessage))
              }
            }
          }
        }

        if success {
          return Promise.value(txid)
        } else {
          self?.analyticsManager.track(event: .paymentSentFailed, with: analyticEvents)
          return Promise(error: returnError)
        }
    }
  }

  private func broadcastRegtestTx(with transactionMetadata: CNBCnlibTransactionMetadata) -> Promise<String> {
    return cnProvider.requestVoid(BroadcastTarget.sendRawTransaction(transactionMetadata.encodedTx))
      .map { _ in return transactionMetadata.txid }
  }

  func postSharedPayloadIfAppropriate(withPostableObject object: SharedPayloadPostableObject,
                                      walletManager: WalletManagerType) -> Promise<String> {
    let sharedPayloadDTO = object.sharedPayloadDTO

    guard case let .known(addressPubKey) = sharedPayloadDTO.addressPubKeyState else {
        //Skip posting payload and just return the txid
        return Promise.value(object.paymentId)
    }

    guard let amountInfo = sharedPayloadDTO.amountInfo else {
      return Promise(error: DBTError.Persistence.missingValue(key: "amountInfo"))
    }

    let payload = SharedPayloadV2(txid: object.paymentId,
                                  memo: sharedPayloadDTO.sharingObservantMemo,
                                  amountInfo: amountInfo,
                                  senderIdentity: object.senderIdentity)

    let keyIsEphemeral = sharedPayloadDTO.shouldEncryptWithEphemeralKey
    return walletManager.encryptPayload(payload, addressPubKey: addressPubKey, keyIsEphemeral: keyIsEphemeral)
      .then { encryptedPayload -> Promise<Void> in
        let body = CreateTransactionNotificationBody(txid: object.paymentId,
                                                     address: object.paymentTarget,
                                                     identityHash: object.receiverIdentityHash,
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
      .map { return object.paymentId }
  }

}

protocol SharedPayloadPostableObject {

  /// txid or ledgerEntry.id
  var paymentId: String { get }

  /// address or encoded invoice
  var paymentTarget: String { get }

  var senderIdentity: UserIdentityBody { get }
  var receiverIdentityHash: String { get }
  var sharedPayloadDTO: SharedPayloadDTO { get }

}

///This may be used for both on chain and lightning transactions when in the flow of an address request (invitation)
struct PayloadPostableOutgoingTransactionData: SharedPayloadPostableObject {
  let paymentId: String
  let paymentTarget: String
  let senderIdentity: UserIdentityBody
  let receiverIdentityHash: String
  let sharedPayloadDTO: SharedPayloadDTO

  init?(data: OutgoingTransactionData) {
    guard let senderIdentity = data.sender else { log.error("Postable data missing sender"); return nil }
    guard let receiverIdentityHash = data.receiver?.identityHash else { log.error("Postable data missing receiver"); return nil }
    guard let payloadDTO = data.sharedPayloadDTO else { log.error("Postable data missing payloadDTO"); return nil }

    self.paymentId = data.txid
    self.paymentTarget = data.destinationAddress
    self.senderIdentity = senderIdentity
    self.receiverIdentityHash = receiverIdentityHash
    self.sharedPayloadDTO = payloadDTO
  }
}

struct PayloadPostableLightningObject: SharedPayloadPostableObject {
  var paymentId: String
  var paymentTarget: String
  var senderIdentity: UserIdentityBody
  var receiverIdentityHash: String
  var sharedPayloadDTO: SharedPayloadDTO

  init?(inputs: LightningPaymentInputs,
        paymentResultId: String,
        sender: UserIdentityBody?,
        receiver: OutgoingDropBitReceiver?) {
    guard let sharedPayloadDTO = inputs.sharedPayload,
      let sender = sender,
      let receiver = receiver
      else { return nil }
    self.paymentId = paymentResultId
    self.paymentTarget = inputs.invoice
    self.senderIdentity = sender
    self.receiverIdentityHash = receiver.identityHash
    self.sharedPayloadDTO = sharedPayloadDTO
  }

}
