//
//  AppCoordinator+PhoneNumberStatusViewControllerDelegate.swift
//  DropBit
//
//  Created by Mitch on 10/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import os.log

extension AppCoordinator: PhoneNumberStatusViewControllerDelegate {
  func viewControllerDidSelectVerifyTwitter(_ viewController: UIViewController) {
    // do something
  }

  func verifiedPhoneNumber() -> GlobalPhoneNumber? {
    return persistenceManager.verifiedPhoneNumber()
  }

  func verifiedTwitterHandle() -> String? {
    return nil
  }

  func viewControllerDidRequestAddresses() -> [ServerAddressViewModel] {
    var addresses: [ServerAddressViewModel] = []

    let context = persistenceManager.createBackgroundContext()
    context.performAndWait {
      addresses = persistenceManager.serverPoolAddresses(in: context)
        .compactMap { ServerAddressViewModel(serverAddress: $0) }
    }

    return addresses
  }

  func viewControllerDidRequestToUnverifyPhone(_ viewController: UIViewController, successfulCompletion: @escaping () -> Void) {
    let okConfiguration = AlertActionConfiguration(title: "OK", style: .default, action: {
      let title = "Are you sure you want to remove your number? You will be able to add a new number after your current number is removed."
      let removeConfiguration = self.createRemoveConfiguration(with: self.createTryAgainConfiguration(viewController, with: successfulCompletion),
                                                               successfulCompletion: successfulCompletion)
      let alert = self.alertManager.alert(withTitle: title,
                                          description: nil,
                                          image: nil,
                                          style: .alert,
                                          actionConfigs: [self.createCancelConfiguration(), removeConfiguration])
      self.navigationController.topViewController()?.present(alert, animated: true, completion: nil)
    })

    let title = "If you change or remove your current phone number, all pending DropBits will be canceled."
    let description = "In order to change your phone number we must first remove it from your account."
    let alert = alertManager.detailedAlert(withTitle: title, description: description, image: #imageLiteral(resourceName: "roundedAppIcon"), style: .warning, action: okConfiguration)
    navigationController.topViewController()?.present(alert, animated: true)
  }

  func viewControllerDidRequestToUnverifyTwitter(_ viewController: UIViewController, successfulCompletion: @escaping () -> Void) {

  }

  func viewControllerDidSelectVerifyPhone(_ viewController: UIViewController) {
    viewController.dismiss(animated: true) {
      self.startDeviceVerificationFlow(shouldOrphanRoot: false)
      self.navigationController.isNavigationBarHidden = false
    }
  }

  private func createCancelConfiguration() -> AlertActionConfiguration {
    return AlertActionConfiguration(title: "Cancel", style: .default, action: nil)
  }

  private func createTryAgainConfiguration(_ viewController: UIViewController,
                                           with successfulCompletion: @escaping () -> Void) -> AlertActionConfiguration {
    return AlertActionConfiguration(title: "Try Again", style: .default, action: {
      self.analyticsManager.track(event: .tryAgainToDeverify, with: nil)
      self.viewControllerDidRequestToUnverifyPhone(viewController, successfulCompletion: successfulCompletion)
    })
  }

  private func createRemoveConfiguration(with tryAgainConfiguration: AlertActionConfiguration,
                                         successfulCompletion: @escaping () -> Void) -> AlertActionConfiguration {
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "unverify_phone")
    return AlertActionConfiguration(title: "Remove", style: .cancel, action: {
      self.alertManager.showActivityHUD(withStatus: nil)
      self.networkManager.resetWallet().done(on: .main) {
        self.alertManager.hideActivityHUD(withDelay: nil, completion: nil)
        self.analyticsManager.track(event: .deregisterPhoneNumber, with: nil)
        self.persistenceManager.deregisterPhone()
        self.analyticsManager.track(property: MixpanelProperty(key: .phoneVerified, value: false))
        successfulCompletion()
        }.catch { error in
          os_log("failed to unverify phone: %@", log: logger, type: .error, error.localizedDescription)
          self.alertManager.hideActivityHUD(withDelay: nil, completion: nil)
          let title = "We are currently having trouble removing your phone number. Please try again."
          let alert = self.alertManager.alert(withTitle: title,
                                              description: nil,
                                              image: nil,
                                              style: .alert,
                                              actionConfigs: [self.createCancelConfiguration(), tryAgainConfiguration])
          self.navigationController.topViewController()?.present(alert, animated: true, completion: nil)
      }
    })
  }
}
