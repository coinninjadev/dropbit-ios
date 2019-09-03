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
    // write new words to keychain
    // set words not backed up flag
    // set new WalletManager value on app coordinator
    return Promise.value(())
  }

  func viewControllerStartUpgradingToSegwit(_ viewController: LightningUpgradeStatusViewController) -> Promise<Void> {
    return Promise.value(())
  }

  func viewController(_ viewController: LightningUpgradeStatusViewController, broadcast encodedTx: String) -> Promise<Void> {
    return Promise.value(())
  }
}
