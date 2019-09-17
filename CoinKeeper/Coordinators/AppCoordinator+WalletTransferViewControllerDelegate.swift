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
import CNBitcoinKit

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
                                          exchangeRates: ExchangeRates) -> PaymentData? {
    let context = self.persistenceManager.viewContext
    guard let wallet = CKMWallet.find(in: context) else { return nil }
    let lightningAccount = self.persistenceManager.brokers.lightning.getAccount(forWallet: wallet, in: context)
    return buildNonReplaceableTransactionData(btcAmount: btcAmount, address: lightningAccount.address, exchangeRates: exchangeRates)
  }

  func viewControllerDidConfirmLoad(_ viewController: UIViewController, paymentData transactionData: PaymentData) {
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
