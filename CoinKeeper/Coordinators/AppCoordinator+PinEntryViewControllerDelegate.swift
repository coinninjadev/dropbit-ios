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
      completion: { [weak self] in self?.viewControllerDidSuccessfullyAuthenticate(pinEntryViewController) },
      error: nil
    )
  }

  func viewControllerDidSuccessfullyAuthenticate(_ pinEntryViewController: PinEntryViewController) {
    switch pinEntryViewController.mode {
    case .standard:
      launchStateManager.userWasAuthenticated()
      serialQueueManager.enqueueWalletSyncIfAppropriate(type: .standard, policy: .always,
                                                        completion: nil, fetchResult: nil)

      let presentedVC = navigationController.topViewController() as? PinEntryViewController
      guard let pinVC = presentedVC else { return }
      pinVC.whenAuthenticated?()

    case .paymentVerification(_, let completion), .inviteVerification(let completion),
         .walletDeletion(let completion), .recoveryWords(let completion):
      pinEntryViewController.dismiss(animated: false) {
        completion(.success(true))
      }
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
