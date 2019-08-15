//
//  AppCoordinator+StartViewControllerDelegate.swift
//  CoinKeeper
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
        do {
          try persistenceManager.resetPersistence()
          log.info("Successfully reset persistence after iCloud Restore")
        } catch {
          log.error(error, message: "Failed to reset persistence after iCloud Restore")
        }
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
    launchStateManager.unauthenticateUser()
  }

  func requireAuthenticationIfNeeded() {
    requireAuthenticationIfNeeded(whenAuthenticated: {})
  }

  func requireAuthenticationIfNeeded(whenAuthenticated: @escaping () -> Void) {
    connectionManager.delegate?.connectionManager(connectionManager, didChangeStatusTo: connectionManager.status)
    guard launchStateManager.shouldRequireAuthentication,
      !(navigationController.topViewController()?.isKind(of: PinEntryViewController.classForCoder()) ?? true)
      else { return }

    let pinEntryVC = createPinEntryViewControllerForAppOpen(whenAuthenticated: whenAuthenticated)
    pinEntryVC.modalPresentationStyle = .overCurrentContext
    pinEntryVC.modalTransitionStyle = .crossDissolve

    navigationController.setViewControllers([pinEntryVC], animated: false)
  }

  func createPinEntryViewControllerForAppOpen(whenAuthenticated: @escaping () -> Void) -> PinEntryViewController {
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
                                              success: successHandler,
                                              failure: nil)
  }

}
