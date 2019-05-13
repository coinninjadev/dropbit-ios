//
//  AppCoordinator+PhoneNumberStatusViewControllerDelegate.swift
//  DropBit
//
//  Created by Mitch on 10/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit
import os.log

extension AppCoordinator: PhoneNumberStatusViewControllerDelegate {
  func verifiedPhoneNumber() -> GlobalPhoneNumber? {
    return persistenceManager.verifiedPhoneNumber()
  }

  func verifiedTwitterHandle() -> String? {
    return persistenceManager.keychainManager.oauthCredentials()?.twitterScreenName
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
    let okTitle = "Are you sure you want to remove your number? You will be able to add a new number after your current number is removed."
    let okConfiguration = unverifyOKConfiguration(
      title: okTitle,
      identityType: .phone,
      viewController: viewController,
      successfulCompletion: successfulCompletion)

    let title = "If you change or remove your current phone number, all pending DropBits will be canceled."
    let description = "In order to change your phone number we must first remove it from your account."
    let image = UIImage(imageLiteralResourceName: "roundedAppIcon")
    let alert = alertManager.detailedAlert(withTitle: title, description: description, image: image, style: .warning, action: okConfiguration)
    navigationController.topViewController()?.present(alert, animated: true)
  }

  func viewControllerDidRequestToUnverifyTwitter(_ viewController: UIViewController, successfulCompletion: @escaping () -> Void) {
    let okTitle = "Are you sure you want to remove your Twitter account? You will be able to add a new account after your current account is removed."
    let okConfiguration = unverifyOKConfiguration(
      title: okTitle,
      identityType: .twitter,
      viewController: viewController,
      successfulCompletion: successfulCompletion)

    let title = "If you change or remove your current Twitter account, all pending DropBits will be canceled."
    let description = "In order to change your Twitter account we must first remove it from your account."
    let image = UIImage(imageLiteralResourceName: "roundedAppIcon")
    let alert = alertManager.detailedAlert(withTitle: title, description: description, image: image, style: .warning, action: okConfiguration)
    navigationController.topViewController()?.present(alert, animated: true)
  }

  func viewControllerDidSelectVerifyTwitter(_ viewController: UIViewController) {
    viewController.dismiss(animated: true) {
      self.navigationController.setNavigationBarHidden(true, animated: true)
      self.startDeviceVerificationFlow(userIdentityType: .twitter, shouldOrphanRoot: false, isInitialSetupFlow: false)
    }
  }

  func viewControllerDidSelectVerifyPhone(_ viewController: UIViewController) {
    viewController.dismiss(animated: true) {
      self.startDeviceVerificationFlow(userIdentityType: .phone, shouldOrphanRoot: false, isInitialSetupFlow: false)
      self.navigationController.setNavigationBarHidden(false, animated: true)
    }
  }

  private func unverifyOKConfiguration(
    title: String,
    identityType: UserIdentityType,
    viewController: UIViewController,
    successfulCompletion: @escaping () -> Void) -> AlertActionConfiguration {

    let okConfiguration = AlertActionConfiguration(title: "OK", style: .default, action: {
      let removeConfiguration = self.createRemoveConfiguration(
        for: identityType,
        with: self.createTryAgainConfiguration(
          viewController,
          with: successfulCompletion),
        successfulCompletion: successfulCompletion)
      let alert = self.alertManager.alert(withTitle: title,
                                          description: nil,
                                          image: nil,
                                          style: .alert,
                                          actionConfigs: [self.createCancelConfiguration(), removeConfiguration])
      self.navigationController.topViewController()?.present(alert, animated: true, completion: nil)
    })
    return okConfiguration
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

  private func createRemoveConfiguration(
    for identityType: UserIdentityType,
    with tryAgainConfiguration: AlertActionConfiguration,
    successfulCompletion: @escaping () -> Void) -> AlertActionConfiguration {

    let verifiedIdentities = persistenceManager.verifiedIdentities()

    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "unverify_phone")
    return AlertActionConfiguration(title: "Remove", style: .cancel, action: {
      self.alertManager.showActivityHUD(withStatus: nil)
      self.unverifyVerifiedIdentity(identityType: identityType, allVerifiedIdentities: verifiedIdentities)
        .then { _ -> Promise<Void> in
          // if there was only one identity, which was removed in `unverifyVerifiedIdentity`, then reset wallet
          if verifiedIdentities.count == 1 {
            self.persistenceManager.deregisterPhone()
            return self.networkManager.resetWallet()
          } else {
            return Promise.value(())
          }
        }
        .done(on: .main) {
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

  private func unverifyTwitterConfiguration(identity: String) -> Promise<Void> {
    let context = persistenceManager.mainQueueContext()
    return self.persistenceManager.defaultHeaders(in: context)
      .then { self.networkManager.deleteIdentity(headers: $0, identity: identity) }
      .done { _ in
        self.alertManager.hideActivityHUD(withDelay: nil, completion: nil)
        self.analyticsManager.track(event: .deregisterTwitter, with: nil)
        self.persistenceManager.keychainManager.unverifyUser(for: .twitter)
        self.analyticsManager.track(property: MixpanelProperty(key: .twitterVerified, value: false))
    }
  }

  private func unverifyPhoneConfiguration(identity: String) -> Promise<Void> {
    let context = persistenceManager.mainQueueContext()
    return self.persistenceManager.defaultHeaders(in: context)
      .then { self.networkManager.deleteIdentity(headers: $0, identity: identity) }
      .done { _ in
        self.alertManager.hideActivityHUD(withDelay: nil, completion: nil)
        self.analyticsManager.track(event: .deregisterPhoneNumber, with: nil)
        self.persistenceManager.keychainManager.unverifyUser(for: .phone)
        self.analyticsManager.track(property: MixpanelProperty(key: .phoneVerified, value: false))
    }
  }

  private func unverifyVerifiedIdentity(identityType: UserIdentityType, allVerifiedIdentities: [UserIdentityType]) -> Promise<Void> {
    let hashingManager = HashingManager()
    var identityToRemove = ""
    switch identityType {
    case .twitter:
      if allVerifiedIdentities.contains(.twitter),
        let creds = persistenceManager.keychainManager.oauthCredentials() {
        identityToRemove = creds.twitterUserId
        return unverifyTwitterConfiguration(identity: identityToRemove)
      } else {
        return Promise(error: DeviceVerificationError.invalidPhoneNumber)
      }
    case .phone:
      if allVerifiedIdentities.contains(.phone),
        let phoneNumber = persistenceManager.verifiedPhoneNumber(),
        let salt = try? hashingManager.salt() {

        identityToRemove = HashingManager().hash(phoneNumber: phoneNumber, salt: salt, parsedNumber: nil, kit: phoneNumberKit)
        return unverifyPhoneConfiguration(identity: identityToRemove)
      } else {
        return Promise(error: DeviceVerificationError.invalidPhoneNumber)
      }
    }

  }
}
