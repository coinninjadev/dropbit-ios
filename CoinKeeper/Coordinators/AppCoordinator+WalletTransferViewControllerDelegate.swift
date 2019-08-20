//
//  AppCoordinator+WalletTransferViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: WalletTransferViewControllerDelegate {

  func viewControllerDidConfirmTransfer(_ viewController: UIViewController,
                                        direction: TransferDirection,
                                        btcAmount: NSDecimalNumber,
                                        exchangeRates: ExchangeRates) {
    switch direction {
    case .toLightning:
      let context = self.persistenceManager.mainQueueContext()
      let wallet = CKMWallet.findOrCreate(in: context)
      let lightningAccount = self.persistenceManager.brokers.lightning.getAccount(forWallet: wallet, in: context)
      let address = lightningAccount.address

      let sharedPayload = SharedPayloadDTO.emptyInstance()

      let inputs = SendingDelegateInputs(primaryCurrency: .BTC, walletTxType: .onChain, contact: nil,
                                         rates: exchangeRates, sharedPayload: sharedPayload)
      viewControllerDidSendPayment(viewController, btcAmount: btcAmount, requiredFeeRate: nil,
                                   destination: address, inputs: inputs)

    case .toOnChain:
      guard let receiveAddress = self.nextReceiveAddressForRequestPay() else { return }
      let sats = btcAmount.asFractionalUnits(of: .BTC)
      self.networkManager.withdrawLightningFunds(to: receiveAddress, sats: sats)
        .done { response in
          viewController.dismiss(animated: true, completion: nil)
        }
        .catch { error in
          log.error(error, message: "Failed to withdraw from lightning account")
      }
    }
  }
}
