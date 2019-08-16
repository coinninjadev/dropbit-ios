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

    let context = self.persistenceManager.mainQueueContext()
    let wallet = CKMWallet.findOrCreate(in: context)
    let lightningAccount = self.persistenceManager.brokers.lightning.getAccount(forWallet: wallet, in: context)
    let address = lightningAccount.address

    let sharedPayload = SharedPayloadDTO.emptyInstance()
    viewControllerDidSendPayment(viewController,
                                 btcAmount: btcAmount,
                                 requiredFeeRate: nil,
                                 primaryCurrency: .BTC,
                                 destination: address,
                                 walletTransactionType: .onChain,
                                 contact: nil,
                                 rates: exchangeRates,
                                 sharedPayload: sharedPayload)
  }
}
