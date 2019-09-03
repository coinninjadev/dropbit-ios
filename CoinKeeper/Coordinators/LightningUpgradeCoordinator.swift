//
//  LightningUpgradeCoordinator.swift
//  DropBit
//
//  Created by BJ Miller on 9/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

class LightningUpgradeCoordinator: ChildCoordinatorType {
  weak var delegate: ChildCoordinatorDelegate?
  weak var parent: AppCoordinator?
  var newWords: [String] = []
  var newWallet: CNBHDWallet?

  var transactionData: CNBTransactionData?

  init(parent: AppCoordinator) {
    self.delegate = parent
    self.parent = parent
  }

  func start() {
    let controller = LightningUpgradePageViewController.newInstance(withGeneralCoordinationDelegate: self)
    parent?.navigationController.present(controller, animated: true, completion: nil)

    parent?.launchStateManager.upgradeInProgress = true
    parent?.serialQueueManager.enqueueWalletSyncIfAppropriate(
      type: .comprehensive,
      policy: EnqueueingPolicy.always,
      completion: { [weak self] (error: Error?) in
        if let error = error {
          // handle error
          log.error(error, message: "Failed to do a full sync of blockchain.")
        } else {
          guard let localSelf = self, let parent = localSelf.parent else { return }
          let feeRate = parent.persistenceManager.brokers.checkIn.cachedBetterFee
          var coinType: CoinType = .MainNet
          #if DEBUG
          coinType = .TestNet
          #endif
          let upgradedCoin = CNBBaseCoin(purpose: .BIP84, coin: coinType, account: 0)
          let tempWords = WalletManager.createMnemonicWords()
          localSelf.newWords = tempWords
          let upgradedWallet = WalletManager(words: localSelf.newWords, purpose: upgradedCoin.purpose, persistenceManager: parent.persistenceManager)
          localSelf.newWallet = CNBHDWallet(mnemonic: tempWords, coin: upgradedCoin)
          let firstAddress = upgradedWallet.createAddressDataSource().receiveAddress(at: 0).address
          log.info("")
          upgradedWallet.transactionDataSendingMax(to: firstAddress, withFeeRate: feeRate)
            .done { (data: CNBTransactionData) in controller.updateUI(with: data) }
            .catch { (error: Error) in
              log.error(error, message: "Failed to create send max transaction.")
              controller.updateUI(with: nil)
            }
            .finally {
              parent.launchStateManager.upgradeInProgress = false
            }
        }
      },
      fetchResult: nil)
  }
}
