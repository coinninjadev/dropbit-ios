//
//  AppCoordinator+StartViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: StartViewControllerDelegate {

  func restoreWallet() {
    startSetupFlow(.restoreWallet)
  }

  func restoreWalletAfterICloudRestore() {
    log.info("Starting Restore after iCloud Restore")
    startSetupFlow(.restoreWallet, restoreFromICloudBackup: true)
  }

  func claimInvite() {
    startSetupFlow(.claimInvite(method: nil))
  }

  func createWallet() {
    startSetupFlow(.newWallet)
  }

  private func startSetupFlow(_ flow: SetupFlow, restoreFromICloudBackup: Bool = false) {
    navigationController.isNavigationBarHidden = false
    launchStateManager.selectedSetupFlow = flow

    switch flow {
    case .restoreWallet:
      if restoreFromICloudBackup {
        let context = persistenceManager.viewContext
        persistenceManager.brokers.wallet.removeWalletId(in: context)
        persistenceManager.brokers.user.unverifyUser(in: context)
        persistenceManager.keychainManager.deleteAll()
        log.info("Successfully reset persistence after iCloud Restore")
      }
      persistenceManager.userDefaultsManager.deleteAll()
      continueSetupFlow()

    case .newWallet, .claimInvite:
      startNewWalletFlow(flow: flow)
    }
  }

  /// temporary function for debugging
  func clearPin() {
    persistenceManager.keychainManager.storeSynchronously(anyValue: nil, key: .userPin)
    persistenceManager.keychainManager.storeSynchronously(anyValue: nil, key: .walletWords)
    persistenceManager.keychainManager.storeSynchronously(anyValue: nil, key: .walletWordsV2)
    launchStateManager.unauthenticateUser()
  }

  func requireAuthenticationIfNeeded() {
    requireAuthenticationIfNeeded(whenAuthenticated: {})
  }

  func requireAuthenticationIfNeeded(whenAuthenticated: @escaping CKCompletion) {
    connectionManager.delegate?.connectionManager(connectionManager, didChangeStatusTo: connectionManager.status)
    guard launchStateManager.shouldRequireAuthentication,
      !(navigationController.topViewController()?.isKind(of: PinEntryViewController.classForCoder()) ?? true)
      else { return }

    let pinEntryVC = createPinEntryViewControllerForAppOpen(whenAuthenticated: whenAuthenticated)
    pinEntryVC.modalPresentationStyle = .overCurrentContext
    pinEntryVC.modalTransitionStyle = .crossDissolve

    navigationController.setViewControllers([pinEntryVC], animated: false)
  }

  func createPinEntryViewControllerForAppOpen(whenAuthenticated: @escaping CKCompletion) -> PinEntryViewController {
    let viewModel = OpenAppPinEntryViewModel()

    let successHandler: CKCompletion = { [weak self] in
      guard let self = self else { return }
      self.launchStateManager.userWasAuthenticated()
      self.serialQueueManager.enqueueWalletSyncIfAppropriate(type: .standard, policy: .always,
                                                             completion: nil, fetchResult: nil)
      whenAuthenticated()
    }

    return PinEntryViewController.newInstance(delegate: self,
                                              viewModel: viewModel,
                                              success: successHandler)
  }

}
