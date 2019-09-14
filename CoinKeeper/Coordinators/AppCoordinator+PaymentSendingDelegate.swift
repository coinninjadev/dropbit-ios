//
//  AppCoordinator+PaymentDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit
import UIKit
import PromiseKit

extension AppCoordinator: PaymentSendingDelegate {

  func viewControllerDidConfirmLightningPayment(_ viewController: UIViewController,
                                                inputs: LightningPaymentInputs,
                                                receiver: OutgoingDropBitReceiver?) {
    let viewModel = PaymentVerificationPinEntryViewModel(amountDisablesBiometrics: false)
    let successHandler: CKCompletion = { [unowned self] in
      self.handleSuccessfulLightningPaymentVerification(with: inputs, receiver: receiver)
    }

    let pinEntryVC = PinEntryViewController.newInstance(delegate: self,
                                                        viewModel: viewModel,
                                                        success: successHandler)
    presentPinEntryViewController(pinEntryVC)
  }

  func viewControllerDidConfirmOnChainPayment(
    _ viewController: UIViewController,
    transactionData: CNBTransactionData,
    rates: ExchangeRates,
    outgoingTransactionData: OutgoingTransactionData
    ) {
    biometricsAuthenticationManager.resetPolicy()

    let converter = CurrencyConverter(fromBtcTo: .USD,
                                      fromAmount: NSDecimalNumber(integerAmount: outgoingTransactionData.amount, currency: .BTC),
                                      rates: rates)
    let amountInfo = SharedPayloadAmountInfo(converter: converter)
    var outgoingTxDataWithAmount = outgoingTransactionData
    outgoingTxDataWithAmount.sharedPayloadDTO?.amountInfo = amountInfo
    outgoingTxDataWithAmount.sender = self.senderIdentity(forReceiver: outgoingTransactionData.receiver)

    let usdThreshold = 100_00
    let shouldDisableBiometrics = amountInfo.fiatAmount > usdThreshold

    let pinEntryViewModel = PaymentVerificationPinEntryViewModel(amountDisablesBiometrics: shouldDisableBiometrics)

    let successHandler: CKCompletion = { [unowned self] in
      self.analyticsManager.track(event: .preBroadcast, with: nil)
      self.handleSuccessfulOnChainPaymentVerification(with: transactionData, outgoingTransactionData: outgoingTxDataWithAmount)
    }

    let pinEntryVC = PinEntryViewController.newInstance(delegate: self,
                                                        viewModel: pinEntryViewModel,
                                                        success: successHandler)
    presentPinEntryViewController(pinEntryVC)
  }

  func viewControllerRequestedShowFeeTooExpensiveAlert(_ viewController: UIViewController) {
    let message = """
    In order to use this fee option you must adjust the amount you are sending.
    The current amount you are sending with the cost of this fee is more than you have in your wallet.
    """
    let alert = alertManager.defaultAlert(withTitle: "Insufficient Funds", description: message)
    viewController.present(alert, animated: true, completion: nil)
  }

  func handleSuccessfulLightningPaymentVerification(with inputs: LightningPaymentInputs, receiver: OutgoingDropBitReceiver?) {
    let viewModel = PaymentSuccessFailViewModel(mode: .pending)
    let successFailVC = SuccessFailViewController.newInstance(viewModel: viewModel, delegate: self)
    let errorHandler: CKErrorCompletion = self.paymentErrorHandler(for: successFailVC)

    successFailVC.action = { [unowned self] in
      self.executeConfirmedLightningPayment(with: inputs,
                                            receiver: receiver,
                                            success: { successFailVC.setMode(.success) },
                                            failure: errorHandler)
    }

    self.navigationController.topViewController()?.present(successFailVC, animated: false) {
      successFailVC.action?()
    }
  }

  func handleSuccessfulOnChainPaymentVerification(
    with transactionData: CNBTransactionData,
    outgoingTransactionData: OutgoingTransactionData,
    isInternalBroadcast: Bool = false) {

    let viewModel = PaymentSuccessFailViewModel(mode: .pending)
    let successFailVC = SuccessFailViewController.newInstance(viewModel: viewModel, delegate: self)
    let errorHandler: CKErrorCompletion = self.paymentErrorHandler(for: successFailVC)

    successFailVC.action = { [unowned self] in
      self.broadcastConfirmedOnChainTransaction(
        with: transactionData,
        outgoingTransactionData: outgoingTransactionData,
        success: { successFailVC.setMode(.success) },
        failure: errorHandler,
        isInternalBroadcast: isInternalBroadcast)
    }

    self.navigationController.topViewController()?.present(successFailVC, animated: false) {
      successFailVC.action?()
    }
  }

  /// Provides a completion handler to be called in the catch block of payment promise chains
  private func paymentErrorHandler(for successFailVC: SuccessFailViewController) -> CKErrorCompletion {
    let errorHandler: CKErrorCompletion = { [unowned self] error in
      if let networkError = error as? CKNetworkError,
        case let .reachabilityFailed(moyaError) = networkError {
        self.handleReachabilityError(moyaError)

      } else {
        self.handleFailure(error: error, action: {
          successFailVC.setMode(.failure)
        })
      }
    }
    return errorHandler
  }

  private func executeConfirmedLightningPayment(with inputs: LightningPaymentInputs,
                                                receiver: OutgoingDropBitReceiver?,
                                                success: @escaping CKCompletion,
                                                failure: @escaping CKErrorCompletion) {
    //TODO: Get updated ledger and persist new entry immediately following payment
    self.networkManager.payLightningPaymentRequest(inputs.invoice, sats: inputs.sats)
      .get { self.persistLightningPaymentResponse($0, receiver: receiver, inputs: inputs) }
      .then { response -> Promise<String> in
        let maybeSender = self.senderIdentity(forReceiver: receiver)
        let maybePostable = PayloadPostableLightningObject(inputs: inputs, paymentResultId: response.result.cleanedId,
                                                           sender: maybeSender, receiver: receiver)
        if let postableObject = maybePostable {
          return self.postSharedPayload(postableObject)
        } else {
          return Promise.value(response.result.cleanedId)
        }
      }
      .done { _ in
        success()
        self.didBroadcastTransaction()
      }
      .catch(failure)
  }

  func persistLightningPaymentResponse(_ response: LNTransactionResponse,
                                       receiver: OutgoingDropBitReceiver?,
                                       inputs: LightningPaymentInputs) {
    let context = self.persistenceManager.createBackgroundContext()
    context.performAndWait {
      self.persistenceManager.brokers.lightning.persistPaymentResponse(response, receiver: receiver,
                                                                       inputs: inputs, in: context)
      try? context.saveRecursively()
    }
  }

  private func postSharedPayload(_ postableObject: SharedPayloadPostableObject) -> Promise<String> {
    guard let wmgr = self.walletManager else {
      return Promise(error: CKPersistenceError.missingValue(key: "walletManager"))
    }

    return self.networkManager.postSharedPayloadIfAppropriate(withPostableObject: postableObject, walletManager: wmgr)
  }

  func senderIdentity(forReceiver receiver: OutgoingDropBitReceiver?) -> UserIdentityBody? {
    guard let receiver = receiver else { return nil }
    let senderIdentityFactory = SenderIdentityFactory(persistenceManager: persistenceManager)
    return senderIdentityFactory.preferredSharedPayloadSenderIdentity(forReceiver: receiver)
  }

  private func broadcastConfirmedOnChainTransaction(with transactionData: CNBTransactionData,
                                                    outgoingTransactionData: OutgoingTransactionData,
                                                    success: @escaping CKCompletion,
                                                    failure: @escaping CKErrorCompletion,
                                                    isInternalBroadcast: Bool = false) {
    self.networkManager.updateCachedMetadata()
      .then { _ in self.networkManager.broadcastTx(with: transactionData) }
      .then { txid -> Promise<String> in
        let dataCopyWithTxid = outgoingTransactionData.copy(withTxid: txid)
        if let postableObject = PayloadPostableOutgoingTransactionData(data: dataCopyWithTxid) {
          return self.postSharedPayload(postableObject)
        } else {
          return Promise.value(txid)
        }
      }
      .get { txid in
        let context = self.persistenceManager.createBackgroundContext()

        context.performAndWait {
          let vouts = transactionData.unspentTransactionOutputs.map { CKMVout.find(from: $0, in: context) }.compactMap { $0 }
          let voutDebugDesc = vouts.map { $0.debugDescription }.joined(separator: "\n")
          log.debug("Broadcast succeeded, vouts: \n\(voutDebugDesc)")
          let persistedTransaction = self.persistenceManager.brokers.transaction.persistTemporaryTransaction(
            from: transactionData,
            with: outgoingTransactionData,
            txid: txid,
            invitation: nil,
            in: context
          )

          if let wallet = self.walletManager?.wallet {
            let transactionBuilder = CNBTransactionBuilder()
            let metadata = transactionBuilder.generateTxMetadata(with: transactionData, wallet: wallet)
            do {
              // If sending max such that there is no change address, an error will be thrown and caught below
              let tempVout = try CKMVout.findOrCreateTemporaryVout(in: context, with: transactionData, metadata: metadata)
              tempVout.transaction = persistedTransaction
            } catch {
              log.error(error, message: "error creating temp vout")
            }
          }

          do {
            try context.save()
          } catch {
            log.contextSaveError(error)
          }
        }
      }
      .done(on: .main) { _ in
        success()

        if !isInternalBroadcast {
          self.showShareTransactionIfAppropriate(dropBitReceiver: outgoingTransactionData.receiver, delegate: self)
        }

        self.analyticsManager.track(property: MixpanelProperty(key: .hasSent, value: true))
        if let receiver = outgoingTransactionData.receiver, case .twitter = receiver {
          self.analyticsManager.track(event: .twitterSendComplete, with: nil)
        }
        self.trackIfUserHasABalance()

        self.didBroadcastTransaction()
      }.catch { error in
        let nsError = error as NSError
        let broadcastError = TransactionBroadcastError(errorCode: nsError.code)
        let context = self.persistenceManager.createBackgroundContext()
        context.performAndWait {
          let vouts = transactionData.unspentTransactionOutputs.map { CKMVout.find(from: $0, in: context) }.compactMap { $0 }
          let voutDebugDesc = vouts.map { $0.debugDescription }.joined(separator: "\n")
          let encodedTx = nsError.userInfo["encoded_tx"] as? String ?? ""
          let txid = nsError.userInfo["txid"] as? String ?? ""
          let analyticsError = "error code: \(broadcastError.rawValue) :: txid: \(txid) :: encoded_tx: \(encodedTx) :: vouts: \(voutDebugDesc)"
          log.error("broadcast failed, \(analyticsError)")
          let eventValue = AnalyticsEventValue(key: .broadcastFailed, value: analyticsError)
          self.analyticsManager.track(event: .paymentSentFailed, with: eventValue)
        }

        failure(error)
    }
  }
}
