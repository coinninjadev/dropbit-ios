//
//  LightningUpgradeCoordinator.swift
//  DropBit
//
//  Created by BJ Miller on 9/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

protocol LightningUpgradeCoordinatorDelegate: AnyObject {
  func coordinatorDidCompleteUpgrade(_ coordinator: LightningUpgradeCoordinator)
  func coordinatorRequestedVerifyUpgradedWords(_ coordinator: LightningUpgradeCoordinator)
}

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

  var coordinationDelegate: LightningUpgradeCoordinatorDelegate? {
    return parent
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
          let newWallet = CNBHDWallet(mnemonic: tempWords, coin: upgradedCoin)
          localSelf.newWallet = newWallet
          let dataSource = AddressDataSource(wallet: newWallet, persistenceManager: parent.persistenceManager)
          let firstAddress = dataSource.changeAddress(at: 0).address
          log.info("Creating send-max transaction to upgraded wallet.")
          parent.walletManager?.transactionDataSendingMax(to: firstAddress, withFeeRate: feeRate)
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
