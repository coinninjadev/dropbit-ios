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

  func coordinator(_ coordinator: DeviceVerificationCoordinator, didVerify phoneNumber: GlobalPhoneNumber) {
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
    alertManager.showBanner(
      with: "Your phone number has been successfully verified. You can now send DropBits to your contacts.",
      duration: .custom(5))
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

}
