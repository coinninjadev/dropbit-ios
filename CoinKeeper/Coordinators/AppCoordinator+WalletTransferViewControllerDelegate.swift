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
    let context = self.persistenceManager.mainQueueContext()
    let wallet = CKMWallet.findOrCreate(in: context)
    var outgoingTransactionData = OutgoingTransactionData.emptyInstance()
    let lightningAccount = self.persistenceManager.brokers.lightning.getAccount(forWallet: wallet, in: context)
    let sharedPayload = SharedPayloadDTO.emptyInstance()
    let inputs = SendingDelegateInputs(primaryCurrency: .BTC, walletTxType: .onChain, contact: nil,
                                       rates: exchangeRates, sharedPayload: sharedPayload)

    outgoingTransactionData = configureOutgoingTransactionData(with: outgoingTransactionData, address: lightningAccount.address, inputs: inputs)
    guard let bitcoinKitTransactionData = walletManager?.failableTransactionData(forPayment: btcAmount, to: lightningAccount.address, withFeeRate: 0.0) else { return nil }// TODO

    return PaymentData(broadcastData: bitcoinKitTransactionData, outgoingData: outgoingTransactionData)
  }

  func viewControllerDidConfirmLoad(_ viewController: UIViewController, paymentData transactionData: PaymentData) {
    handleSuccessfulOnChainPaymentVerification(with: transactionData.broadcastData, outgoingTransactionData: transactionData.outgoingData)
  }

  func viewControllerDidConfirmWithdraw(_ viewController: UIViewController, lightningData: LightningPaymentInputs) {
    // TODO: Implement
  }

  func viewControllerDidConfirmTransfer(_ viewController: UIViewController,
                                        direction: TransferDirection,
                                        btcAmount: NSDecimalNumber,
                                        exchangeRates: ExchangeRates) {
    switch direction {
    case .toOnChain:
      guard let receiveAddress = self.nextReceiveAddressForRequestPay() else { return }
      let sats = btcAmount.asFractionalUnits(of: .BTC)
      self.networkManager.withdrawLightningFunds(to: receiveAddress, sats: sats)
        .done { _ in
          viewController.dismiss(animated: true, completion: nil)
        }
        .catch { error in
          log.error(error, message: "Failed to withdraw from lightning account")
      }
    default:
      break
    }
  }
}
