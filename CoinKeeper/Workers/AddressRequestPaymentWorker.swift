//
//  AddressRequestPaymentWorker.swift
//  DropBit
//
//  Created by Ben Winters on 9/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import Moya
import PromiseKit
import UIKit

/// Create new instances of this as needed, do not assign them to an instance variable.
class AddressRequestPaymentWorker {

  let networkManager: NetworkManagerType
  let walletManager: WalletManagerType
  let persistenceManager: PersistenceManagerType
  let analyticsManager: AnalyticsManagerType
  weak var paymentSendingDelegate: AllPaymentSendingDelegate?

  init(walletAddressDataWorker worker: WalletAddressDataWorker, paymentDelegate: AllPaymentSendingDelegate) {
    self.networkManager = worker.networkManager
    self.walletManager = worker.walletManager
    self.persistenceManager = worker.persistenceManager
    self.analyticsManager = worker.analyticsManager
    self.paymentSendingDelegate = paymentDelegate
  }

  func completeWalletAddressRequestFulfillmentLocally(outgoingTransactionData: OutgoingTransactionData,
                                                      invitationId: String,
                                                      pendingInvitation: CKMInvitation,
                                                      txData: CNBTransactionData?,
                                                      in context: NSManagedObjectContext) -> Promise<Void> {
    guard let postableObject = PayloadPostableOutgoingTransactionData(data: outgoingTransactionData) else {
      return Promise(error: CKPersistenceError.missingValue(key: "postableOutgoingTransactionData"))
    }

    return self.networkManager.postSharedPayloadIfAppropriate(withPostableObject: postableObject, walletManager: self.walletManager)
      .get(in: context) { (paymentId: String) in
        if let transactionData = txData {
          self.persistenceManager.brokers.transaction.persistTemporaryTransaction(
            from: transactionData,
            with: outgoingTransactionData,
            txid: paymentId,
            invitation: pendingInvitation,
            in: context)
        } else {
          // update and match them manually, partially matching code in `persistTemporaryTransaction`
          pendingInvitation.setTxid(to: paymentId)
          pendingInvitation.status = .completed
          //TODO: Link pendingInvitation to LNTransactionResult
          if let existingTransaction = CKMTransaction.find(byTxid: paymentId, in: context), pendingInvitation.transaction !== existingTransaction {
            let txToRemove = pendingInvitation.transaction
            pendingInvitation.transaction = existingTransaction
            txToRemove.map { context.delete($0) }
            existingTransaction.phoneNumber = pendingInvitation.counterpartyPhoneNumber
          }
        }

        if pendingInvitation.status == .completed {
          self.analyticsManager.track(event: .dropbitCompleted, with: nil)
          if let receiver = outgoingTransactionData.receiver, case .twitter = receiver {
            self.analyticsManager.track(event: .twitterSendComplete, with: nil)
          }
        }

      }
      .then { (paymentId: String) -> Promise<WalletAddressRequestResponse> in
        let request = WalletAddressRequest(walletAddressRequestStatus: .completed, txid: paymentId)
        return self.networkManager.updateWalletAddressRequest(for: invitationId, with: request)
      }
      .then { _ in
        return Promise.value(())
    }
  }

  /// paymentTarget may be either a BTC address or lightning invoice
  func outgoingTransactionData(for response: WalletAddressRequestResponse,
                               paymentTarget: String,
                               invitation: CKMInvitation) -> OutgoingTransactionData {
    let sharedPayloadDTO = self.sharedPayload(forInvitation: invitation, walletAddressRequestResponse: response)

    var contact: ContactType?
    // create outgoing dto object
    if let twitterContact = invitation.counterpartyTwitterContact {
      let twitterUser = twitterContact.asTwitterUser()
      contact = TwitterContact(twitterUser: twitterUser)
    } else if let phoneContact = invitation.counterpartyPhoneNumber {
      let global = phoneContact.asGlobalPhoneNumber
      let genericContact = GenericContact(phoneNumber: global, formatted: global.asE164())
      contact = genericContact
    }

    let btcAmount = invitation.btcAmount
    let maybeReceiver: OutgoingDropBitReceiver? = contact?.asDropBitReceiver
    let identityFactory = SenderIdentityFactory(persistenceManager: self.persistenceManager)
    let senderIdentity = identityFactory.preferredSharedPayloadSenderIdentity(forReceiver: maybeReceiver)

    let outgoingTransactionData = OutgoingTransactionData(
      txid: "",
      destinationAddress: paymentTarget,
      amount: btcAmount,
      feeAmount: invitation.fees,
      sentToSelf: false,
      requiredFeeRate: nil,
      sharedPayloadDTO: sharedPayloadDTO,
      sender: senderIdentity,
      receiver: maybeReceiver
    )
    return outgoingTransactionData
  }

  private func sharedPayload(forInvitation invitation: CKMInvitation,
                             walletAddressRequestResponse response: WalletAddressRequestResponse) -> SharedPayloadDTO {
    let walletTxType = WalletTransactionType(addressType: response.addressTypeCase)

    if let ckmPayload = invitation.transaction?.sharedPayload,
      let fiatCurrency = CurrencyCode(rawValue: ckmPayload.fiatCurrency),
      let pubKey = response.addressPubkey {
      let amountInfo = SharedPayloadAmountInfo(fiatCurrency: fiatCurrency, fiatAmount: ckmPayload.fiatAmount)
      return SharedPayloadDTO(addressPubKeyState: .known(pubKey),
                              walletTxType: walletTxType,
                              sharingDesired: ckmPayload.sharingDesired,
                              memo: invitation.transaction?.memo,
                              amountInfo: amountInfo)

    } else {
      return SharedPayloadDTO(addressPubKeyState: .none, walletTxType: walletTxType,
                              sharingDesired: false, memo: invitation.transaction?.memo, amountInfo: nil)
    }
  }

}

class LightningAddressRequestPaymentWorker: AddressRequestPaymentWorker {

  func payLightningInvitationRequest(with outgoingTxData: OutgoingTransactionData,
                                     pendingInvitation: CKMInvitation,
                                     invoice: String,
                                     responseId: String,
                                     in context: NSManagedObjectContext) -> Promise<Void> {

    let satsToPay = pendingInvitation.totalPendingAmount
    let spendableBalance = self.walletManager.spendableBalance(in: context)
    guard spendableBalance.lightning >= satsToPay else {
      return Promise(error: PendingInvitationError.insufficientFundsForInvitationWithID(responseId))
    }

    guard let paymentDelegate = paymentSendingDelegate else {
      return Promise(error: PendingInvitationError.noPaymentDelegate)
    }

    let lightningInputs = LightningPaymentInputs(sats: satsToPay, invoice: invoice, sharedPayload: outgoingTxData.sharedPayloadDTO)
    return paymentDelegate.payLightningRequest(withInputs: lightningInputs, invitation: pendingInvitation, to: outgoingTxData.receiver)
      .then(in: context) { response -> Promise<Void> in
        var outgoingCopy = outgoingTxData
        outgoingCopy.txid = response.result.cleanedId
        return self.completeWalletAddressRequestFulfillmentLocally(outgoingTransactionData: outgoingCopy, invitationId: responseId,
      pendingInvitation: pendingInvitation, txData: nil, in: context) }
    }
}

class OnChainAddressRequestPaymentWorker: AddressRequestPaymentWorker {

  /// Promise to fulfill an invitation request. This will broadcast the transaction with provided amount and fee,
  ///   tell the network manager to update the invitation (aka wallet address request) with completed status and txid,
  ///   persist a temporary transaction if needed, and clear the pending invitation data from UserDefaults.
  ///
  /// - Parameters:
  ///   - response: An object representing a wallet address request.
  ///   - context: NSManagedObjectContext within which any managed objects will be used. This should be called using `perform` by the caller
  /// - Returns: A Promise containing void upon successfully processing.
  func payOnChainInvitationRequest(with outgoingTxData: OutgoingTransactionData,
                                   pendingInvitation: CKMInvitation,
                                   responseId: String,
                                   in context: NSManagedObjectContext) -> Promise<Void> {
    let btcAmount = pendingInvitation.btcAmount
    let address = outgoingTxData.destinationAddress

    return self.networkManager.fetchTransactionSummaries(for: address)
      .then(in: context) { (summaryResponses: [AddressTransactionSummaryResponse]) -> Promise<Void> in
        // guard against already funded
        let maybeFound = summaryResponses.first { $0.vout == btcAmount }
        if let found = maybeFound {
          let foundOutgoingTxData = outgoingTxData.copy(withTxid: found.txid)
          return self.completeWalletAddressRequestFulfillmentLocally(outgoingTransactionData: foundOutgoingTxData, invitationId: responseId,
                                                                     pendingInvitation: pendingInvitation, txData: nil, in: context)
        } else {

          // guard against insufficient funds
          let spendableBalance = self.walletManager.spendableBalance(in: context)
          let totalPendingAmount = pendingInvitation.totalPendingAmount
          guard spendableBalance.onChain >= totalPendingAmount else {
            return Promise(error: PendingInvitationError.insufficientFundsForInvitationWithID(responseId))
          }

          return self.walletManager.transactionData(forPayment: btcAmount, to: address, withFlatFee: pendingInvitation.fees)
            .then { txData in
              return self.networkManager.broadcastTx(with: txData)
                .then(in: context) { _ -> Promise<Void> in
                  return self.completeWalletAddressRequestFulfillmentLocally(outgoingTransactionData: outgoingTxData, invitationId: responseId,
                                                                             pendingInvitation: pendingInvitation, txData: txData, in: context)
              }
            }
            .recover { self.mapTransactionBroadcastError($0, forResponseId: responseId) }
        }
    }
  }

  private func mapTransactionBroadcastError(_ error: Error, forResponseId responseId: String) -> Promise<Void> {
    if error is MoyaError {
      return Promise(error: error)
    }

    if let txDataError = error as? TransactionDataError {
      switch txDataError {
      case .insufficientFunds, .noSpendableFunds:
        return Promise(error: PendingInvitationError.insufficientFundsForInvitationWithID(responseId))
      case .insufficientFee:
        return Promise(error: PendingInvitationError.insufficientFeeForInvitationWithID(responseId))
      }
    }

    let nsError = error as NSError
    let errorCode = TransactionBroadcastError(errorCode: nsError.code)
    switch errorCode {
    case .broadcastTimedOut:
      return Promise(error: TransactionBroadcastError.broadcastTimedOut)
    case .networkUnreachable:
      return Promise(error: TransactionBroadcastError.networkUnreachable)
    case .unknown:
      return Promise(error: TransactionBroadcastError.unknown)
    case .insufficientFee:
      return Promise(error: PendingInvitationError.insufficientFeeForInvitationWithID(responseId))
    }
  }

}
