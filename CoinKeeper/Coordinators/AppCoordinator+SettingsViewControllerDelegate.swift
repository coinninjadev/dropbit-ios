//
//  AppCoordinator+SettingsViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit
import UIKit
import os.log
import Permission

extension AppCoordinator: SettingsViewControllerDelegate {

  func verifyIfWordsAreBackedUp() -> Bool {
    return wordsBackedUp
  }

  func dustProtectionIsEnabled() -> Bool {
    return persistenceManager.brokers.preferences.dustProtectionIsEnabled
  }

  func yearlyHighPushNotificationIsSubscribed() -> Bool {
    let permission = permissionManager.permissionStatus(for: .notification)
    let permissionGranted = permission == .authorized
    let hasPushToken = persistenceManager.brokers.device.pushToken != nil
    let isEnabled = persistenceManager.brokers.preferences.yearlyPriceHighNotificationIsEnabled
    return isEnabled && permissionGranted && hasPushToken
  }

  func viewControllerDidSelectRecoveryWords(_ viewController: UIViewController) {
    viewController.dismiss(animated: true, completion: {
      self.showWordRecoveryFlow()
    })
  }

  func viewControllerDidSelectOpenSourceLicenses(_ viewController: UIViewController) {
    guard let privacyPolicyHtml = Bundle.main.path(forResource: "licenses", ofType: "html"),
      let html = try? String(contentsOfFile: privacyPolicyHtml, encoding: String.Encoding.utf8),
      let navigationController = viewController.navigationController else { return }
    let textViewController = TextViewController.makeFromStoryboard()
    textViewController.htmlString = html
    navigationController.pushViewController(textViewController, animated: true)
  }

  func viewController(_ viewController: UIViewController, didEnableDustProtection didEnable: Bool) {
    self.persistenceManager.brokers.preferences.dustProtectionIsEnabled = didEnable
  }

  func viewController(_ viewController: UIViewController, didEnableYearlyHighNotification didEnable: Bool, completion: @escaping () -> Void) {
    permissionManager.requestPermission(for: .notification) { (status: PermissionStatus) in
      switch status {
      case .authorized, .notDetermined:
        guard self.persistenceManager.brokers.device.pushToken != nil else {
          self.requestPushNotificationDialogueIfNeeded()
          completion()
          return
        }

        self.persistenceManager.brokers.preferences.yearlyPriceHighNotificationIsEnabled = didEnable

        if didEnable {
          self.notificationManager.subscribeToTopic(type: .btcHigh)
            .ensure { completion() }.cauterize()

        } else {
          self.notificationManager.unsubscribeFromTopic(type: .btcHigh)
            .ensure { completion() }.cauterize()
        }

      case .denied, .disabled:
        completion()
      }
    }
  }

  func viewController(_ viewController: UIViewController, didRequestOpenURL url: URL) {
    openURL(url, completionHandler: nil)
  }

  func viewControllerDidRequestDeleteWallet(_ viewController: UIViewController, completion: @escaping () -> Void) {
    let description = """
        Are you sure you want to delete this wallet?
        Make sure you have your recovery words before you delete.\n
    """
    let settingsViewController = navigationController.topViewController()
    let deleteAction = AlertActionConfiguration(title: "Delete", style: .default) { [weak self] in
      guard let strongSelf = self else { return }
      let pinEntryViewController = PinEntryViewController.makeFromStoryboard()
      strongSelf.resetUserAuthenticatedState()
      strongSelf.assignCoordinationDelegate(to: pinEntryViewController)
      pinEntryViewController.mode = .walletDeletion(completion: { result in
        switch result {
        case .success:
          pinEntryViewController.dismiss(animated: true, completion: nil)
          completion()
        default:
          break
        }
      })

      settingsViewController?.present(pinEntryViewController, animated: true, completion: nil)
    }
    let cancelAction = AlertActionConfiguration(title: "Cancel", style: .default, action: nil)
    let configs = [cancelAction, deleteAction]
    let alert = alertManager.alert(withTitle: "", description: description,
                                   image: nil, style: .alert, actionConfigs: configs)
    settingsViewController?.present(alert, animated: true)
  }

  func viewControllerDidConfirmDeleteWallet(_ viewController: UIViewController) {
    let deleteWalletOperation = AsynchronousOperation(operationType: .deleteWallet)
    deleteWalletOperation.task = { operation in
      _ = self.deleteDeviceEndpoint()
        .recover { (error: Error) -> Promise<Void> in
          let logger = OSLog(subsystem: "com.coinninja.coinkeeper.AppCoordinator", category: "delete_wallet")
          os_log("failed to delete endpoint in %@: %@", log: logger, type: .error, #function, error.localizedDescription)
          return Promise.value(()) // don't show error, just go on with deleting wallet.
        }
        .then { self.networkManager.resetWallet() }
        .get { try self.deleteAndResetWalletLocally() }
        .done(on: .main) { _ in
          self.analyticsManager.track(event: .deleteWallet, with: nil)
          self.showStartViewController()
          self.analyticsManager.track(property: MixpanelProperty(key: .hasWallet, value: false))
          self.analyticsManager.track(property: MixpanelProperty(key: .phoneVerified, value: false))
          self.analyticsManager.track(property: MixpanelProperty(key: .twitterVerified, value: false))
          self.analyticsManager.track(property: MixpanelProperty(key: .wordsBackedUp, value: false))
          self.analyticsManager.track(property: MixpanelProperty(key: .hasBTCBalance, value: false))
          self.analyticsManager.track(property: MixpanelProperty(key: .isDropBitMeEnabled, value: false))
        }.catch { error in
          let logger = OSLog(subsystem: "com.coinninja.coinkeeper.AppCoordinator", category: "delete_wallet")
          os_log("Error in %@: %@", log: logger, type: .error, #function, error.localizedDescription)
        }.finally {
          operation.finish()
      }
    }

    self.serialQueueManager.enqueueOperationIfAppropriate(deleteWalletOperation, policy: .skipIfSimilarOperationExists)
  }

  func viewControllerResyncBlockchain(_ viewController: UIViewController) {
    analyticsManager.track(event: .syncBlockchain, with: nil)
    alertManager.showActivityHUD(withStatus: "Synchronizing...")
    let successMessage = "Blockchain successfully re-synchronized. Please check your transaction history to verify."

    let completion: CompletionHandler = { error in
      if let err = error {
        self.alertManager.hideActivityHUD(withDelay: 1.0) {
          self.alertManager.showError(message: "Something went wrong. Please try again.\n\nError: \(err.localizedDescription)", forDuration: 3.0)
        }
      } else {
        self.alertManager.hideActivityHUD(withDelay: 1.0) {
          self.alertManager.showSuccess(message: successMessage, forDuration: 3.0)
        }
      }
    }

    serialQueueManager.enqueueWalletSyncIfAppropriate(
      type: .comprehensive,
      policy: .skipIfSpecificOperationExists,
      completion: completion,
      fetchResult: nil
    )
  }

  private func deleteDeviceEndpoint() -> Promise<Void> {
    guard let endpointIds = persistenceManager.brokers.device.deviceEndpointIds() else {
      return .value(())
    }

    // Delete IDs locally only if the server request was successful
    return self.networkManager.deleteDeviceEndpoint(forIds: endpointIds)
      .get { self.persistenceManager.brokers.device.deleteDeviceEndpointIds() }
  }

  private func deleteAndResetWalletLocally() throws {
    try persistenceManager.brokers.wallet.resetWallet()
    resetUserAuthenticatedState()
    walletManager = nil
  }

  private func showStartViewController() {
    let startViewController = StartViewController.makeFromStoryboard()
    navigationController.setViewControllers([startViewController], animated: false)
    navigationController.isNavigationBarHidden = false
    assignCoordinationDelegate(to: startViewController)
  }
}
