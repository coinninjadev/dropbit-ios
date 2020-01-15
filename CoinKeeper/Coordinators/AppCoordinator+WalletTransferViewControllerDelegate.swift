//
//  AppCoordinator+WalletTransferViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

extension AppCoordinator: WalletTransferViewControllerDelegate {

  func viewControllerDidRequestWithdrawMax(_ viewController: UIViewController) -> Promise<LNTransactionResponse> {
    guard let receiveAddress = self.nextReceiveAddressForRequestPay() else { return Promise { _ in } }
    return networkManager.withdrawMaxLightningAmountEstimate(to: receiveAddress)
  }

  func viewControllerNeedsFeeEstimates(_ viewController: UIViewController, btcAmount: NSDecimalNumber) -> Promise<LNTransactionResponse> {
    guard let receiveAddress = self.nextReceiveAddressForRequestPay() else { return Promise { _ in } }
    let sats = btcAmount.asFractionalUnits(of: .BTC)

    return networkManager.estimateLightningWithdrawalFees(to: receiveAddress, sats: sats)
  }

  func viewControllerDidConfirmWithdrawMax(_ viewController: UIViewController) {
    viewControllerDidConfirmWithdraw(viewController, btcAmount: LNTransactionTarget.withdrawMaxInBTC)
  }

  func viewControllerDidConfirmWithdraw(_ viewController: UIViewController, btcAmount: NSDecimalNumber) {
    let context = self.persistenceManager.createBackgroundContext()

    guard let receiveAddress = self.nextReceiveAddressForRequestPay() else { return }
    let sats = btcAmount.asFractionalUnits(of: .BTC)

    let viewModel = PaymentSuccessFailViewModel(mode: .pending)
    let successFailVC = SuccessFailViewController.newInstance(viewModel: viewModel, delegate: self)

    successFailVC.action = { [unowned self] in
      self.networkManager.withdrawLightningFunds(to: receiveAddress, sats: sats)
        .done(in: context) { response in
          guard let wallet = CKMWallet.find(in: context) else { return }
          self.persistenceManager.brokers.transaction.persistTemporaryTransaction(from: response, in: context)
          self.persistLightningPaymentResponse(response, receiver: nil, invitation: nil, inputs: nil)
          self.workerFactory().createTransactionDataWorker()?.processOnChainLightningTransfers(withLedger: [response.result],
                                                                                          forWallet: wallet,
                                                                                          in: context)
          self.analyticsManager.track(event: .lightningToOnChainSuccessful, with: nil)
          successFailVC.setMode(.success)
          do {
            try context.saveRecursively()
            CKNotificationCenter.publish(key: .didUpdateLocalTransactionRecords)
          } catch {
            log.contextSaveError(error)
          }
        }
        .catch { error in
          let dbtError = DBTErrorWrapper.wrap(error)
          log.error(error, message: "Failed to withdraw from lightning account. \(dbtError.displayMessage)")
          successFailVC.setMode(.failure)
      }
    }

    viewController.dismiss(animated: false) {
      self.toggleChartAndBalance()
      self.navigationController.topViewController()?.present(successFailVC, animated: false) {
        successFailVC.action?()
      }
    }
  }

  func lightningPaymentData(forFiatAmount fiatAmount: NSDecimalNumber, isMax: Bool) -> Promise<PaymentData> {
    let context = self.persistenceManager.viewContext
    let exchangeRates = self.currencyController.exchangeRates
    let converter = CurrencyConverter(rates: exchangeRates, fromAmount: fiatAmount, currencyPair: .USD_BTC)
    if isMax {
      return buildLoadLightningPaymentData(selectedAmount: .max, exchangeRates: exchangeRates, in: context)
    } else {
      return buildLoadLightningPaymentData(selectedAmount: .specific(converter.btcAmount), exchangeRates: exchangeRates, in: context)
    }
  }

  func lightningPaymentData(forBTCAmount btcAmount: NSDecimalNumber) -> Promise<PaymentData> {
    let context = self.persistenceManager.viewContext
    let exchangeRates = self.currencyController.exchangeRates
    return buildLoadLightningPaymentData(selectedAmount: .specific(btcAmount), exchangeRates: exchangeRates, in: context)
  }

  func viewControllerDidConfirmLoad(_ viewController: UIViewController, paymentData transactionData: PaymentData) {
    viewController.dismiss(animated: false) {
      self.toggleChartAndBalance()
      self.selectLightningWallet()
      self.handleSuccessfulOnChainPaymentVerification(with: transactionData.broadcastData,
                                               outgoingTransactionData: transactionData.outgoingData,
                                               isInternalBroadcast: true)
    }
  }

  func viewControllerNetworkError(_ error: Error) {
    let dbtError = DBTErrorWrapper.wrap(error)
    alertManager.showErrorHUD(dbtError, forDuration: 2.0)
  }
}
