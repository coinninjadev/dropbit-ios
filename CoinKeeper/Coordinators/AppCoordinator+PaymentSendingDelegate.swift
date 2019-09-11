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

  func viewControllerDidConfirmLightningPayment(_ viewController: UIViewController, inputs: LightningPaymentInputs) {
    let viewModel = PaymentVerificationPinEntryViewModel(amountDisablesBiometrics: false)
    let successHandler: CKCompletion = { [unowned self] in
      self.handleSuccessfulLightningPaymentVerification(with: inputs)
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

    let senderIdentityFactory = SenderIdentityFactory(persistenceManager: persistenceManager)
    let senderIdentity = senderIdentityFactory.preferredSharedPayloadSenderIdentity(forDropBitType: outgoingTransactionData.dropBitType)
    outgoingTxDataWithAmount.sharedPayloadSenderIdentity = senderIdentity

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

  func handleSuccessfulLightningPaymentVerification(with inputs: LightningPaymentInputs) {
    let viewModel = PaymentSuccessFailViewModel(mode: .pending)
    let successFailVC = SuccessFailViewController.newInstance(viewModel: viewModel, delegate: self)
    let errorHandler: CKErrorCompletion = self.paymentErrorHandler(for: successFailVC)

    successFailVC.action = { [unowned self] in
      self.executeConfirmedLightningPayment(with: inputs,
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
                                                success: @escaping CKCompletion,
                                                failure: @escaping CKErrorCompletion) {
    //TODO: Get updated ledger and persist new entry immediately following payment
    self.networkManager.payLightningPaymentRequest(inputs.invoice, sats: inputs.sats).asVoid()
      .done { _ in
        success()
        self.didBroadcastTransaction()
      }
      .catch(failure)
  }

  private func broadcastConfirmedOnChainTransaction(with transactionData: CNBTransactionData,
                                                    outgoingTransactionData: OutgoingTransactionData,
                                                    success: @escaping CKCompletion,
                                                    failure: @escaping CKErrorCompletion,
                                                    isInternalBroadcast: Bool = false) {
    self.networkManager.updateCachedMetadata()
      .then { _ in self.networkManager.broadcastTx(with: transactionData) }
      .then { txid -> Promise<String> in
        guard let wmgr = self.walletManager else {
          return Promise(error: CKPersistenceError.missingValue(key: "walletManager"))
        }

        let dataCopyWithTxid = outgoingTransactionData.copy(withTxid: txid)
        guard let postableObject = PayloadPostableOutgoingTransactionData(data: dataCopyWithTxid) else {
          return Promise(error: CKPersistenceError.missingValue(key: "postableOutgoingTransactionData") )
        }
        return self.networkManager.postSharedPayloadIfAppropriate(withPostableObject: postableObject, walletManager: wmgr)
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

          if let walletCopy = self.walletManager?.createWalletCopy() {
            let transactionBuilder = CNBTransactionBuilder()
            let metadata = transactionBuilder.generateTxMetadata(with: transactionData, wallet: walletCopy)
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
          self.showShareTransactionIfAppropriate(dropBitType: .none, delegate: self)
        }

        self.analyticsManager.track(property: MixpanelProperty(key: .hasSent, value: true))
        if case .twitter = outgoingTransactionData.dropBitType {
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
