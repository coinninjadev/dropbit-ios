//
//  AppCoordinator+DeviceVerificationCoordinatorDelegate.swift
//  CoinKeeper
//
//  Created by Ben Winters on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import PromiseKit
import os.log

extension AppCoordinator: DeviceVerificationCoordinatorDelegate {

  /**
   Kicks off an API call to register the wallet with the server based on its public key,
   then persists the wallet ID returned by the server response.
   Call this after the seed words are backed up or skipped.
   */
  func registerAndPersistWallet(in context: NSManagedObjectContext) -> Promise<Void> {
    guard let wmgr = walletManager else { return Promise(error: CKPersistenceError.noWalletWords) }
    // Skip registration if wallet was previously registered and persisted
    guard self.persistenceManager.walletId(in: context) == nil else {
      return Promise { $0.fulfill(()) }
    }

    return self.networkManager.createWallet(withPublicKey: wmgr.hexEncodedPublicKey)
      .then(in: context) { self.persistenceManager.persistWalletId(from: $0, in: context) }
  }

  func coordinator(_ coordinator: DeviceVerificationCoordinator, didVerify phoneNumber: GlobalPhoneNumber, isInitialSetupFlow: Bool) {
    analyticsManager.track(event: .phoneVerified, with: nil)
    analyticsManager.track(property: MixpanelProperty(key: .phoneVerified, value: true))

    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "phone_verification")
    if launchStateManager.profileIsActivated() {
      os_log("Profile is activated, will register wallet addresses", log: logger, type: .debug)
      registerInitialWalletAddresses()
    }

    persistenceManager.keychainManager.store(anyValue: NSNumber(value: false), key: .skippedVerification)

    serialQueueManager.enqueueWalletSyncIfAppropriate(type: .comprehensive, policy: .skipIfSpecificOperationExists,
                                                      completion: nil, fetchResult: nil)
    childCoordinatorDidComplete(childCoordinator: coordinator)
    continueSetupFlow()

    if !isInitialSetupFlow {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.presentDropBitMeViewController(verifiedFirstTime: true)
      }
    }
  }

  func coordinatorSkippedPhoneVerification(_ coordinator: DeviceVerificationCoordinator) {
    analyticsManager.track(event: .skipPhoneVerification, with: nil)
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "phone_verification")
    os_log("Skipped verification", log: logger, type: .debug)

    persistenceManager.keychainManager.store(anyValue: NSNumber(value: true), key: .skippedVerification)

    serialQueueManager.enqueueWalletSyncIfAppropriate(type: .comprehensive, policy: .skipIfSpecificOperationExists,
                                                      completion: nil, fetchResult: nil)
    childCoordinatorDidComplete(childCoordinator: coordinator)
    continueSetupFlow()
  }

  func didReceiveTwilioError(for phoneNumber: String, route: TwilioErrorRoute) {
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "twilio_error")
    let parser = CKPhoneNumberParser(kit: self.phoneNumberKit)
    let e164 = "+" + phoneNumber

    guard let maybeNumber = try? parser.parse(e164), let globalNumber = maybeNumber else {
      os_log("Failed to parse phone number for Twilio error", log: logger, type: .error)
      return
    }

    os_log("Failed to send SMS to country code: %@, route: %@", log: logger, type: .error, String(globalNumber.countryCode), route.rawValue)

    let eventValue = AnalyticsEventValue(key: .countryCode, value: "\(globalNumber.countryCode)")
    switch route {
    case .createAddressRequest:
      analyticsManager.track(event: .dropbitInviteSMSFailed, with: eventValue)
    case .createUser, .resendVerification:
      analyticsManager.track(event: .verifyUserSMSFailed, with: eventValue)
    }
  }

  /// This may fail with a 500 error if the addresses were already added during a previous installation of the same wallet
  private func registerInitialWalletAddresses() {
    guard let walletWorker = createWalletAddressDataWorker() else { return }
    let bgContext = persistenceManager.createBackgroundContext()
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "register_wallet_addresses")
    let addressNumber = walletWorker.targetWalletAddressCount
    bgContext.perform {
      walletWorker.deleteAllAddressesOnServer()
        .then(in: bgContext) { walletWorker.registerAndPersistServerAddresses(number: addressNumber, in: bgContext) }
        .get(in: bgContext) { _ in
          bgContext.perform {
            try? bgContext.save()
          }
        }
        .catch(policy: .allErrors) { os_log("failed to register wallet addresses: %@", log: logger, type: .error, $0.localizedDescription) }
    }
  }

}
