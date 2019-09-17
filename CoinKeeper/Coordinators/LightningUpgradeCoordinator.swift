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
  weak var childCoordinatorDelegate: ChildCoordinatorDelegate!
  weak var parent: AppCoordinator!
  var newWords: [String] = []
  var newWallet: CNBHDWallet?

  var transactionData: CNBTransactionData?

  init(parent: AppCoordinator) {
    self.childCoordinatorDelegate = parent
    self.parent = parent
  }

  var coordinationDelegate: LightningUpgradeCoordinatorDelegate? {
    return parent
  }

  func start() {
    let controller = LightningUpgradePageViewController.newInstance(withGeneralCoordinationDelegate: self)
    parent.navigationController.present(controller, animated: true, completion: nil)

    parent.launchStateManager.upgradeInProgress = true
    let context = parent.persistenceManager.createBackgroundContext()
    parent.serialQueueManager.walletSyncOperationFactory?.createOnChainOnlySync(in: context)
      .get(in: context) { _ in
        do {
          try context.saveRecursively()
        } catch {
          log.contextSaveError(error)
        }
      }
      .done { self.proceedWithUpgrade(presentedController: controller) }
      .catch { (error: Error) in
        log.error(error, message: "Failed to do a full sync of blockchain prior to upgrade.")

        let alertVM = AlertControllerViewModel(title: "We were unable to perform a sync. Please try again later.")
        let alert = self.parent.alertManager.alert(from: alertVM)
        self.parent.navigationController.topViewController()?.present(alert, animated: true, completion: nil)
    }
  }

  private func proceedWithUpgrade(presentedController controller: LightningUpgradePageViewController) {
    guard let wallet = parent.walletManager?.wallet else { return }

    let feeRate = parent.persistenceManager.brokers.checkIn.cachedBetterFee
    var coinType: CoinType = .MainNet
    #if DEBUG
    coinType = CKUserDefaults().useRegtest ? .TestNet : .MainNet
    #endif
    let upgradedCoin = CNBBaseCoin(purpose: .BIP84, coin: coinType, account: 0)
    let tempWords = WalletManager.createMnemonicWords()
    self.newWords = tempWords
    let newWallet = CNBHDWallet(mnemonic: tempWords, coin: upgradedCoin)
    self.newWallet = newWallet
    let dataSource = AddressDataSource(wallet: newWallet, persistenceManager: parent.persistenceManager)
    let destinationAddress = dataSource.changeAddress(at: 0).address
    log.info("Creating send-max transaction to upgraded wallet.")
    parent.walletManager?.transactionDataSendingAll(to: destinationAddress, withFeeRate: feeRate)
      .done { (data: CNBTransactionData) in
        let builder = CNBTransactionBuilder()
        let metadata = builder.generateTxMetadata(with: data, wallet: wallet)
        controller.updateUI(with: data, txMetadata: metadata)
      }
      .catch { (error: Error) in
        log.error(error, message: "Failed to create send max transaction.")
        if let txError = error as? TransactionDataError {
          switch txError {
          case .noSpendableFunds:
            controller.updateUI(with: nil, txMetadata: nil)
          default:
            let tryAgain = AlertActionConfiguration(title: "Try Again", style: .default, action: { [weak self] in
              self?.proceedWithUpgrade(presentedController: controller)
            })
            let alertVM = AlertControllerViewModel(title: txError.localizedDescription,
                                                   description: txError.messageDescription,
                                                   image: nil,
                                                   style: .alert,
                                                   actions: [tryAgain])
            let alert = self.parent.alertManager.alert(from: alertVM)
            self.parent.navigationController.topViewController()?.present(alert, animated: true, completion: nil)
          }
        }
      }
  }
}
