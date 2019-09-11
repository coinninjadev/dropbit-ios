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

  func viewControllerNeedsTransactionData(_ viewController: UIViewController,
                                          btcAmount: NSDecimalNumber,
                                          exchangeRates: ExchangeRates) -> PaymentData? {
    let context = self.persistenceManager.viewContext
    let wallet = CKMWallet.findOrCreate(in: context)
    let lightningAccount = self.persistenceManager.brokers.lightning.getAccount(forWallet: wallet, in: context)
    return buildNonReplaceableTransactionData(btcAmount: btcAmount, address: lightningAccount.address, exchangeRates: exchangeRates)
  }

  func viewControllerDidConfirmLoad(_ viewController: UIViewController, paymentData transactionData: PaymentData) {
    handleSuccessfulOnChainPaymentVerification(with: transactionData.broadcastData, outgoingTransactionData: transactionData.outgoingData)
  }

  func viewControllerDidConfirmWithdraw(_ viewController: UIViewController, btcAmount: NSDecimalNumber) {
    guard let receiveAddress = self.nextReceiveAddressForRequestPay() else { return }
    let sats = btcAmount.asFractionalUnits(of: .BTC)
    self.networkManager.withdrawLightningFunds(to: receiveAddress, sats: sats)
      .done { _ in
        viewController.dismiss(animated: true, completion: nil)
      }
      .catch { error in
        log.error(error, message: "Failed to withdraw from lightning account")
    }
  }

  func viewControllerHasFundsError(_ error: Error) {
    alertManager.showError(message: error.localizedDescription, forDuration: 2.0)
  }
}
