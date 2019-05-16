//
//  AppCoordinator+PinVerificationDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: PinVerificationDelegate {
  func pinWasVerified(digits: String, for flow: PinCreationViewController.Flow) {
    _ = persistenceManager.keychainManager.store(userPin: digits)
    launchStateManager.userWasAuthenticated()

    var finally: (() -> Void)?

    switch flow {
    case .creation:
      finally = { [weak self] in
        self?.startCreateRecoveryWordsFlow()
      }
    case .restore:
      finally = { [weak self] in
        let viewController = RestoreWalletViewController.makeFromStoryboard()
        self?.assignCoordinationDelegate(to: viewController)
        self?.navigationController.pushViewController(viewController, animated: true)
      }
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
