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

  func claimInvite() {
    startSetupFlow(.claimInvite)
  }

  func createWallet() {
    startSetupFlow(.newWallet)
  }

  private func startSetupFlow(_ flow: SetupFlow) {
    navigationController.isNavigationBarHidden = false
    launchStateManager.selectedSetupFlow = flow

    switch flow {
    case .restoreWallet:
      persistenceManager.userDefaultsManager.deleteAll()
      continueSetupFlow()

    case .newWallet, .claimInvite:
      startNewWalletFlow()
    }
  }

  /// temporary function for debugging
  func clearPin() {
    persistenceManager.keychainManager.storeSynchronously(anyValue: nil, key: .userPin)
    persistenceManager.keychainManager.storeSynchronously(anyValue: nil, key: .walletWords)
    launchStateManager.unauthenticateUser()
  }

  func requireAuthenticationIfNeeded(whenAuthenticated: (() -> Void)?) {
    connectionManager.delegate?.connectionManager(connectionManager, didChangeStatusTo: connectionManager.status)
    guard launchStateManager.shouldRequireAuthentication,
      !(navigationController.topViewController()?.isKind(of: PinEntryViewController.classForCoder()) ?? true)
      else { return }

    let pinEntryVC = PinEntryViewController.makeFromStoryboard()
    // This closure is called by its delegate's implementation of viewControllerDidSuccessfullyAuthenticate()
    pinEntryVC.whenAuthenticated = whenAuthenticated
    assignCoordinationDelegate(to: pinEntryVC)

    pinEntryVC.modalPresentationStyle = .overCurrentContext
    pinEntryVC.modalTransitionStyle = .crossDissolve
    navigationController.setViewControllers([pinEntryVC], animated: false)
  }

}
