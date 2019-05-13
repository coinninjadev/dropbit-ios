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
    continueSetupFlow()
  }

  func claimInvite() {
    navigationController.isNavigationBarHidden = false
  }

  func restoreWallet() {
    persistenceManager.userDefaultsManager.deleteAll()
    navigationController.isNavigationBarHidden = false
    let viewController = PinCreationViewController.makeFromStoryboard()
    viewController.flow = .restore
    assignCoordinationDelegate(to: viewController)
    navigationController.pushViewController(viewController, animated: true)
  }

  /// temporary function for debugging
  func clearPin() {
    persistenceManager.keychainManager.store(anyValue: nil, key: .userPin)
    persistenceManager.keychainManager.store(anyValue: nil, key: .walletWords)
    launchStateManager.unauthenticateUser()
  }
}
