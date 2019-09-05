//
//  LightningUpgradeCoordinator+LightningUpgradeStatusViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 8/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
import CNBitcoinKit

extension LightningUpgradeCoordinator: LightningUpgradeStatusViewControllerDelegate {
  func viewControllerDidRequestUpgradedWallet(_ viewController: LightningUpgradeStatusViewController) -> CNBHDWallet? {
    return newWallet
  }

  func viewControllerStartUpgradingWallet(_ viewController: LightningUpgradeStatusViewController) -> Promise<Void> {
    guard let parent = parent else { return Promise(error: CKPersistenceError.missingValue(key: "parent coordinator")) }

    let mainQueueContext = parent.persistenceManager.mainQueueContext()
    let existingFlags = parent.persistenceManager.brokers.wallet.walletFlags(in: mainQueueContext)

    let newFlags = WalletFlagsParser(flags: 0)
      .setPurpose(.BIP84)
      .setVersion(.v2)

    let context = parent.persistenceManager.createBackgroundContext()

    existingFlags.deactivate()
    return parent.networkManager.updateWallet(walletFlags: existingFlags.flags)
      .then { (response: WalletResponse) -> Promise<Void> in
        let flagsParser = WalletFlagsParser(flags: response.flags)
        guard flagsParser.walletDeactivated else { throw CKWalletError.failedToDeactivate }
        return parent.persistenceManager.keychainManager.upgrade(recoveryWords: self.newWords)
      }
      .then { _ -> Promise<WalletResponse> in
        let newWalletManager = WalletManager(words: self.newWords, persistenceManager: parent.persistenceManager)
        parent.walletManager = newWalletManager
        return parent.networkManager.createWallet(withPublicKey: newWalletManager.hexEncodedPublicKey, walletFlags: newFlags.flags)
      }
      .done(in: context) { (response: WalletResponse) in
        try parent.persistenceManager.brokers.wallet.persistWalletResponse(from: response, in: context)
        let wallet = CKMWallet.find(in: context)
        wallet?.lastReceivedIndex = CKMWallet.defaultLastIndex
        wallet?.lastChangeIndex = CKMWallet.defaultLastIndex + 1 // send-max to segwit wallet goes to first change address
        try context.save()
        parent.persistenceManager.brokers.wallet.receiveAddressIndexGaps = []
      }
      .asVoid()
  }

  func viewControllerStartUpgradingToSegwit(_ viewController: LightningUpgradeStatusViewController) -> Promise<Void> {
    return Promise.value(())
  }

  func viewController(_ viewController: LightningUpgradeStatusViewController, broadcast data: CNBTransactionData) -> Promise<String> {
    guard let parent = parent else { return Promise(error: CKPersistenceError.missingValue(key: "parent coordinator")) }
    return parent.networkManager.broadcastTx(with: data)
  }
}
