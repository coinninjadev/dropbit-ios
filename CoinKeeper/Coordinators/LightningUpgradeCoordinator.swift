//
//  LightningUpgradeCoordinator.swift
//  DropBit
//
//  Created by BJ Miller on 9/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Cnlib
import UIKit

protocol LightningUpgradeCoordinatorDelegate: DebugDelegate {
  func coordinatorWillCompleteUpgrade(_ coordinator: LightningUpgradeCoordinator)
  func coordinatorDidCompleteUpgrade(_ coordinator: LightningUpgradeCoordinator)
  func coordinatorRequestedVerifyUpgradedWords(_ coordinator: LightningUpgradeCoordinator)
}

class LightningUpgradeCoordinator: ChildCoordinatorType {
  weak var childCoordinatorDelegate: ChildCoordinatorDelegate!
  weak var parent: AppCoordinator!
  var newWords: [String] = []
  var newWallet: CNBCnlibHDWallet?

  var transactionData: CNBCnlibTransactionData?

  init(parent: AppCoordinator) {
    self.childCoordinatorDelegate = parent
    self.parent = parent
  }

  var coordinationDelegate: LightningUpgradeCoordinatorDelegate? {
    return parent
  }

  func start() {
    trackUpgradeLaunch()
    let controller = LightningUpgradePageViewController.newInstance(withGeneralCoordinationDelegate: self)
    parent.navigationController.present(controller, animated: true, completion: nil)

    parent.launchStateManager.upgradeInProgress = true
    let context = parent.persistenceManager.createBackgroundContext()

    guard let walletSyncOperationFactory = parent.serialQueueManager.walletSyncOperationFactory else {
      log.info("~*~*~*~*~ Factory is nil")
      presentDebugInfoAlert(withController: controller)
      return
    }

    walletSyncOperationFactory.performOnChainOnlySync(in: context)
      .get(in: context) { _ in
        do {
          try context.saveRecursively()
        } catch {
          log.contextSaveError(error)
          throw error
        }
      }
      .done { self.proceedWithUpgrade(presentedController: controller) }
      .catch { (error: Error) in
        log.error(error, message: "Failed to do a full sync of blockchain prior to upgrade.")

        let alertVM = AlertControllerViewModel(
          title: "We were unable to perform a sync. Please try again later.\nMessage: \(error.localizedDescription)"
        )
        let alert = self.parent.alertManager.alert(from: alertVM)
        self.parent.navigationController.topViewController()?.present(alert, animated: true, completion: nil)
    }
  }

  private func trackUpgradeLaunch() {
    let properties = [
      MixpanelProperty(key: .lightningUpgradeStarted, value: true),
      MixpanelProperty(key: .lightningUpgradeCompleted, value: false),
      MixpanelProperty(key: .lightningUpgradedFunds, value: false),
      MixpanelProperty(key: .lightningUpgradedFromRestore, value: false)
    ]
    properties.forEach { self.parent.analyticsManager.track(property: $0) }
  }

  private func presentDebugInfoAlert(withController controller: UIViewController, error: Error = DBTError.SyncRoutine.missingWalletManager) {
    log.info("~*~*~*~*~ Has wallet words v1: \(parent.persistenceManager.keychainManager.retrieveValue(for: .walletWords) != nil)")
    log.info("~*~*~*~*~ Has wallet words v2: \(parent.persistenceManager.keychainManager.retrieveValue(for: .walletWordsV2) != nil)")
    log.info("~*~*~*~*~ Has pin: \(parent.persistenceManager.keychainManager.retrieveValue(for: .userPin) != nil)")
    log.info("~*~*~*~*~ Is iCloud restore: \(parent.launchStateManager.isFirstTimeAfteriCloudRestore())")

    let alert = parent.alertManager.debugAlert(with: error) {
      self.coordinationDelegate?.viewControllerSendDebuggingInfo(controller)
    }

    DispatchQueue.main.async {
      controller.present(alert, animated: true, completion: nil)
    }
  }

  private func proceedWithUpgrade(presentedController controller: LightningUpgradePageViewController) {
    guard let wallet = parent.walletManager?.wallet else {
      log.info("~*~*~*~*~ Parent's wallet manager is nil")
      presentDebugInfoAlert(withController: controller)
      return
    }

    let feeRate = parent.persistenceManager.brokers.checkIn.cachedBetterFee
    var net = 0
    #if DEBUG
    net = CKUserDefaults().useRegtest ? 1 : 0
    #endif
    let upgradedCoin = CNBCnlibNewBaseCoin(84, net, 0)
    let tempWords = WalletManager.createMnemonicWords()
    self.newWords = tempWords
    let newWallet = CNBCnlibNewHDWalletFromWords(tempWords.joined(separator: " "), upgradedCoin)!
    self.newWallet = newWallet
    let dataSource = AddressDataSource(wallet: newWallet, persistenceManager: parent.persistenceManager)
    var destinationAddress = ""
    do {
      destinationAddress = try dataSource.changeAddress(at: 0).address
    } catch {
      log.error(error, message: "Failed to get change address for new wallet at index 0.")
      presentDebugInfoAlert(withController: controller, error: error)
    }
    log.info("Creating send-max transaction to upgraded wallet.")
    parent.walletManager?.transactionDataSendingAll(to: destinationAddress, withFeeRate: feeRate)
      .done { (data: CNBCnlibTransactionData) in
        do {
          let metadata = try wallet.buildTransactionMetadata(data)
          controller.updateUI(with: data, txMetadata: metadata)
        } catch {
          throw error
        }
      }
      .catch { (error: Error) in
        log.error(error, message: "Failed to create send max transaction.")
        if let txError = error as? DBTError.TransactionData {
          switch txError {
          case .noSpendableFunds:
            controller.updateUI(with: nil, txMetadata: nil)
          default:
            let tryAgain = AlertActionConfiguration(title: "Try Again", style: .default, action: { [weak self] in
              self?.proceedWithUpgrade(presentedController: controller)
            })
            let alertVM = AlertControllerViewModel(title: txError.displayTitle,
                                                   description: txError.displayMessage,
                                                   image: nil,
                                                   style: .alert,
                                                   actions: [tryAgain])
            let alert = self.parent.alertManager.alert(from: alertVM)
            self.parent.navigationController.topViewController()?.present(alert, animated: true, completion: nil)
          }
        } else {
          log.info("~*~*~*~*~ Unknown error type \(error.localizedDescription)")
          self.presentDebugInfoAlert(withController: controller)
        }
      }
  }
}
