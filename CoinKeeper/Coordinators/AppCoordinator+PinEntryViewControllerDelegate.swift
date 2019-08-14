//
//  AppCoordinator+PinEntryViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: PinEntryViewControllerDelegate {

  func viewControllerDidTryBiometrics(_ pinEntryViewController: PinEntryViewController) {
    guard biometricsAuthenticationManager.canAuthenticateWithBiometrics else { return }
    biometricsAuthenticationManager.authenticate(
      completion: {
        pinEntryViewController.authenticationSatisfied()
      },
      error: nil
    )
  }

  func viewControllerDidSuccessfullyAuthenticate(_ pinEntryViewController: PinEntryViewController,
                                                 completion: CompletionHandler?) {
    if pinEntryViewController.viewModel.shouldDismissOnSuccess {
      pinEntryViewController.dismiss(animated: true, completion: completion)
    } else {
      completion?()
    }
  }

  func checkMatch(for digits: String) -> Bool {
    guard let existingHashedPin = persistenceManager.keychainManager.retrieveValue(for: .userPin) as? String else { return false }
    let hashedPin = digits.sha256()
    return existingHashedPin == hashedPin
  }

  var biometricType: BiometricType {
    return biometricsAuthenticationManager.biometricType
  }

  func pinExists() -> Bool {
    return launchStateManager.pinExists()
  }
}
