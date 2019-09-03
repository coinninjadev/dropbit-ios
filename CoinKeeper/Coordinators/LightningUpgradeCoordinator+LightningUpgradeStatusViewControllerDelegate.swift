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

    return parent.persistenceManager.keychainManager.upgrade(recoveryWords: newWords)
      .done { _ in parent.walletManager = WalletManager(words: self.newWords, purpose: .BIP84, persistenceManager: parent.persistenceManager) }
  }

  func viewControllerStartUpgradingToSegwit(_ viewController: LightningUpgradeStatusViewController) -> Promise<Void> {
    return Promise.value(())
  }

  func viewController(_ viewController: LightningUpgradeStatusViewController, broadcast encodedTx: String) -> Promise<Void> {
    return Promise.value(())
  }
}
