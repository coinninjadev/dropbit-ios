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

  func viewControllerNeedsFeeEstimates(_ viewController: UIViewController, btcAmount: NSDecimalNumber) -> Promise<LNTransactionResponse> {
    guard let receiveAddress = self.nextReceiveAddressForRequestPay() else { return Promise { _ in } }
    let sats = btcAmount.asFractionalUnits(of: .BTC)

    return networkManager.estimateLightningWithdrawlFees(to: receiveAddress, sats: sats)
  }

  func viewControllerDidConfirmWithdraw(_ viewController: UIViewController, btcAmount: NSDecimalNumber) {
    guard let receiveAddress = self.nextReceiveAddressForRequestPay() else { return }
    let sats = btcAmount.asFractionalUnits(of: .BTC)

    let viewModel = PaymentSuccessFailViewModel(mode: .pending)
    let successFailVC = SuccessFailViewController.newInstance(viewModel: viewModel, delegate: self)

    successFailVC.action = { [unowned self] in
      self.networkManager.withdrawLightningFunds(to: receiveAddress, sats: sats)
        .done { _ in
          self.analyticsManager.track(event: .lightningToOnChainSuccessful, with: nil)
          CKNotificationCenter.publish(key: .didUpdateLocalTransactionRecords)
          successFailVC.setMode(.success)
        }
        .catch { error in
          log.error(error, message: "Failed to withdraw from lightning account")
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

  func viewControllerNeedsTransactionData(_ viewController: UIViewController,
                                          btcAmount: NSDecimalNumber,
                                          exchangeRates: ExchangeRates) -> Promise<PaymentData> {
    let context = self.persistenceManager.viewContext
    return buildLoadLightningPaymentData(btcAmount: btcAmount, exchangeRates: exchangeRates, in: context)
  }

  func viewControllerDidConfirmLoad(_ viewController: UIViewController,
                                    paymentData transactionData: PaymentData) {
    viewController.dismiss(animated: false) {
      self.toggleChartAndBalance()
      self.handleSuccessfulOnChainPaymentVerification(with: transactionData.broadcastData,
                                               outgoingTransactionData: transactionData.outgoingData,
                                               isInternalBroadcast: true)
    }
  }

  func viewControllerNetworkError(_ error: Error) {
    alertManager.showError(message: error.localizedDescription, forDuration: 2.0)
  }
}
