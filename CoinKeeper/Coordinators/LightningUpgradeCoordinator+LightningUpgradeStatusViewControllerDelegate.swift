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
    let mainQueueContext = parent.persistenceManager.viewContext
    let existingFlags = parent.persistenceManager.brokers.wallet.walletFlags(in: mainQueueContext)

    let newFlags = WalletFlagsParser(flags: 0)
      .setPurpose(.BIP84)
      .setVersion(.v2)

    let context = parent.persistenceManager.createBackgroundContext()
    var newWalletManager: WalletManagerType!

    existingFlags.deactivate()
    return parent.networkManager.updateWallet(walletFlags: existingFlags.flags)
      .then { (response: WalletResponse) -> Promise<Void> in
        let flagsParser = WalletFlagsParser(flags: response.flags)
        guard flagsParser.walletDeactivated else { throw CKWalletError.failedToDeactivate }
        return self.parent.persistenceManager.keychainManager.upgrade(recoveryWords: self.newWords)
      }
      .then { _ -> Promise<WalletResponse> in
        newWalletManager = WalletManager(words: self.newWords, persistenceManager: self.parent.persistenceManager)
        let timestamp = CKDateFormatter.rfc3339.string(from: Date())
        let signature = newWalletManager.signatureSigning(data: timestamp.data(using: .utf8) ?? Data())
        let body = ReplaceWalletBody(publicKeyString: newWalletManager.hexEncodedPublicKey,
                                     flags: newFlags.flags,
                                     timestamp: timestamp,
                                     signature: signature)
        return self.parent.networkManager.replaceWallet(body: body)
      }
      .done(in: context) { (response: WalletResponse) in
        self.parent.walletManager = newWalletManager
        try self.parent.persistenceManager.brokers.wallet.persistWalletResponse(from: response, in: context)
        let wallet = CKMWallet.find(in: context)
        wallet?.lastReceivedIndex = CKMWallet.defaultLastIndex
        wallet?.lastChangeIndex = CKMWallet.defaultLastIndex + 1 // send-max to segwit wallet goes to first change address
        try context.saveRecursively()
        self.parent.persistenceManager.brokers.wallet.receiveAddressIndexGaps = []
      }
      .asVoid()
  }

  func viewControllerStartUpgradingToSegwit(_ viewController: LightningUpgradeStatusViewController) -> Promise<Void> {
    return Promise.value(())
  }

  func viewController(_ viewController: LightningUpgradeStatusViewController, broadcast metadata: CNBTransactionMetadata) -> Promise<String> {
    return parent.networkManager.broadcastTx(metadata: metadata)
  }
}
