//
//  AppCoordinator+PinVerificationDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: PinVerificationDelegate {

  private var lockoutLength: UInt64 {
    return 300
  }

  func pinWasVerified(digits: String, for flow: SetupFlow?) {
    persistenceManager.keychainManager.store(userPin: digits)
      .get { _ in self.setWalletManagerWithPersistedWords() }
      .done { _ in
        self.launchStateManager.userWasAuthenticated()
        let action = self.postVerificationAction(forFlow: flow)
        self.biometricsAuthenticationManager.authenticate(completion: action, error: { _ in action() })
      }
      .catchDisplayable { error in self.alertManager.showError(error, forDuration: 4.0) }
  }

  private func postVerificationAction(forFlow flow: SetupFlow?) -> CKCompletion {
    guard let flow = flow else { return { } }
    switch flow {
    case .newWallet, .claimInvite:
      return { [weak self] in
        self?.continueSetupFlow()
      }

    case .restoreWallet:
      return { [unowned self] in
        let viewController = RestoreWalletViewController.newInstance(delegate: self)
        self.navigationController.pushViewController(viewController, animated: true)
      }
    }
  }

  func viewControllerPinFailureCountExceeded(_ viewController: UIViewController) {
    switch viewController {
    case is PinCreationViewController:
      navigationController.popViewController(animated: true)
      navigationController.topViewController.flatMap { $0 as? PinCreationViewController }?.entryMode = .pinVerificationFailed
    case is PinEntryViewController:
      let lockoutDate = absoluteTime() + lockoutLength  // 300s = 5m
      self.persistenceManager.keychainManager.storeSynchronously(anyValue: lockoutDate, key: .lockoutDate)
    default: break
    }
  }

  func viewControllerShouldAllowPinEntry() -> Bool {
    guard let lockoutDate = self.persistenceManager.keychainManager.retrieveValue(for: .lockoutDate) as? UInt64 else { return true }
    let currentDate = absoluteTime()
    var newLockoutDate = lockoutDate
    if (Int(lockoutDate) - Int(currentDate)) > Int(lockoutLength) {
      newLockoutDate = currentDate + lockoutLength
      self.persistenceManager.keychainManager.storeSynchronously(anyValue: newLockoutDate, key: .lockoutDate)
    }
    return currentDate > newLockoutDate
  }

  private func absoluteTime() -> UInt64 {
    var info = mach_timebase_info_data_t(numer: 0, denom: 0)
    if mach_timebase_info(&info) != KERN_SUCCESS {
      return 0
    }
    let nanoseconds = mach_absolute_time() * UInt64(info.numer / info.denom)
    let absoluteDate = nanoseconds / NSEC_PER_SEC
    return absoluteDate
  }
}
