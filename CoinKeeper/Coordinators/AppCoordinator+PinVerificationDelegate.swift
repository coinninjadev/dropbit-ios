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
    _ = persistenceManager.keychainManager.store(userPin: digits)
    launchStateManager.userWasAuthenticated()

    let finally: (() -> Void)? = { [weak self] in
      self?.startDeviceVerificationFlow(shouldOrphanRoot: false, selectedSetupFlow: flow)
    }

    biometricsAuthenticationManager.authenticate(
      completion: { finally?() },
      error: { _ in finally?() }
    )
  }

  func viewControllerPinFailureCountExceeded(_ viewController: UIViewController) {
    switch viewController {
    case is PinCreationViewController:
      navigationController.popViewController(animated: true)
      navigationController.topViewController.flatMap { $0 as? PinCreationViewController }?.entryMode = .pinVerificationFailed
    case is PinEntryViewController:
      let lockoutDate = Date().timeIntervalSince1970 + 300  // 300s = 5m
      self.persistenceManager.keychainManager.store(anyValue: lockoutDate, key: .lockoutDate)
    default: break
    }
  }

  func viewControllerShouldAllowPinEntry() -> Bool {
    guard let lockoutDate = self.persistenceManager.keychainManager.retrieveValue(for: .lockoutDate) as? TimeInterval else { return true }
    let currentDate = Date().timeIntervalSince1970
    return currentDate > lockoutDate
  }
}
