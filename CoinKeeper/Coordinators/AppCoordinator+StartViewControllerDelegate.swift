//
//  AppCoordinator+StartViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: StartViewControllerDelegate {

  func createWallet() {
    navigationController.isNavigationBarHidden = false
    launchStateManager.selectedSetupFlow = .newWallet
    continueSetupFlow()
  }

  func claimInvite() {
    navigationController.isNavigationBarHidden = false
    launchStateManager.selectedSetupFlow = .claimInvite
    continueSetupFlow()
  }

  func restoreWallet() {
    persistenceManager.userDefaultsManager.deleteAll()
    navigationController.isNavigationBarHidden = false
    let viewController = PinCreationViewController.makeFromStoryboard()
    viewController.flow = .restore
    assignCoordinationDelegate(to: viewController)
    navigationController.pushViewController(viewController, animated: true)
    launchStateManager.selectedSetupFlow = .restoreWallet
    continueSetupFlow()
  }

  /// temporary function for debugging
  func clearPin() {
    persistenceManager.keychainManager.store(anyValue: nil, key: .userPin)
    persistenceManager.keychainManager.store(anyValue: nil, key: .walletWords)
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
