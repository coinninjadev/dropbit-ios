//
//  AppCoordinator+PinVerificationDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: PinVerificationDelegate {

  func pinWasVerified(digits: String, for flow: SetupFlow?) {
    persistenceManager.keychainManager.store(userPin: digits)
      .get { _ in self.setWalletManagerWithPersistedWords() }
      .done { _ in
        self.launchStateManager.userWasAuthenticated()
        let action = self.postVerificationAction(forFlow: flow)
        self.biometricsAuthenticationManager.authenticate(completion: action, error: { _ in action() })
      }.cauterize()
  }

  private func postVerificationAction(forFlow flow: SetupFlow?) -> (() -> Void) {
    guard let flow = flow else { return { } }
    switch flow {
    case .newWallet, .claimInvite:
      return { [weak self] in
        self?.continueSetupFlow()
      }

    case .restoreWallet:
      return { [weak self] in
        let viewController = RestoreWalletViewController.makeFromStoryboard()
        self?.assignCoordinationDelegate(to: viewController)
        self?.navigationController.pushViewController(viewController, animated: true)
      }
    }
  }

  func viewControllerPinFailureCountExceeded(_ viewController: UIViewController) {
    switch viewController {
    case is PinCreationViewController:
      navigationController.popViewController(animated: true)
      navigationController.topViewController.flatMap { $0 as? PinCreationViewController }?.entryMode = .pinVerificationFailed
    case is PinEntryViewController:
      let lockoutDate = Date().timeIntervalSince1970 + 300  // 300s = 5m
      self.persistenceManager.keychainManager.store(anyValue: lockoutDate, key: .lockoutDate).cauterize()
    default: break
    }
  }

  func viewControllerShouldAllowPinEntry() -> Bool {
    guard let lockoutDate = self.persistenceManager.keychainManager.retrieveValue(for: .lockoutDate) as? TimeInterval else { return true }
    let currentDate = Date().timeIntervalSince1970
    return currentDate > lockoutDate
  }
}
