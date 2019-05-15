//
//  AppCoordinator+Lifecycle.swift
//  DropBit
//
//  Created by Ben Winters on 5/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator {

  /// Handle app becoming active
  func appEnteredActiveState() {
    resetWalletManagerIfNeeded()
    connectionManager.start()

    analyticsManager.track(event: .appOpen, with: nil)

    authenticateOnBecomingActiveIfNeeded()

    refreshContacts()
  }

  private func authenticateOnBecomingActiveIfNeeded() {
    defer { self.suspendAuthenticationOnceUntil = nil }
    if let suspendUntil = self.suspendAuthenticationOnceUntil, suspendUntil > Date() {
      return
    }

    // check keychain time interval for resigned time, and if within 30 sec, don't require
    let now = Date().timeIntervalSince1970
    let lastLogin = persistenceManager.lastLoginTime() ?? Date.distantPast.timeIntervalSince1970

    let secondsSinceLastLogin = now - lastLogin
    if secondsSinceLastLogin > maxSecondsInBackground {
      //dismissAllModalViewControllers
      UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: false, completion: nil)
      resetUserAuthenticatedState()
      requireAuthenticationIfNeeded(whenAuthenticated: {
        self.continueSetupFlow()
      })
    }
  }

  /// Called only on first open, after didFinishLaunchingWithOptions, when appEnteredActiveState is not called
  func appBecameActive() {
    resetWalletManagerIfNeeded()
    handlePendingBitcoinURL()
    refreshContacts()

    if self.permissionManager.permissionStatus(for: .location) == .authorized {
      self.locationManager.requestLocation()
    }
  }

  /// Handle app leaving active state, either becoming inactive, entering background, or terminating.
  func appResignedActiveState() {
    persistenceManager.setLastLoginTime()
    connectionManager.stop()
    bitcoinURLToOpen = nil
    //    UIApplication.shared.applicationIconBadgeNumber = persistenceManager.pendingInvitations().count
  }

  func handlePendingBitcoinURL() {
    guard let bitcoinURL = bitcoinURLToOpen, launchStateManager.userAuthenticated else { return }
    bitcoinURLToOpen = nil

    if let topVC = navigationController.topViewController(), let sendPaymentVC = topVC as? SendPaymentViewController {
      sendPaymentVC.applyRecipient(inText: bitcoinURL.absoluteString)

    } else {
      let sendPaymentViewController = SendPaymentViewController.makeFromStoryboard()
      assignCoordinationDelegate(to: sendPaymentViewController)
      sendPaymentViewController.alertManager = alertManager
      sendPaymentViewController.recipientDescriptionToLoad = bitcoinURL.absoluteString
      sendPaymentViewController.viewModel.updatePrimaryCurrency(to: currencyController.selectedCurrency)
      navigationController.present(sendPaymentViewController, animated: true)
    }
  }

}
