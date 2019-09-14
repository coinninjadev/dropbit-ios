//
//  AppCoordinator+DeviceVerificationCoordinatorDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import PromiseKit

extension AppCoordinator: DeviceVerificationCoordinatorDelegate {

  /**
   Kicks off an API call to register the wallet with the server based on its public key,
   then persists the wallet ID returned by the server response.
   Call this after the seed words are backed up or skipped.
   */
  func registerAndPersistWallet(in context: NSManagedObjectContext) -> Promise<Void> {
    guard let wmgr = walletManager else { return Promise(error: CKPersistenceError.noWalletManager) }
    // Skip registration if wallet was previously registered and persisted
    guard self.persistenceManager.brokers.wallet.walletId(in: context) == nil else {
      return Promise.value(())
    }

    let flags = 0
    let handler = WalletFlagsParser(flags: flags)
      .setPurpose(.BIP84)
      .setVersion(.v2)

    return self.networkManager.createWallet(withPublicKey: wmgr.hexEncodedPublicKey, walletFlags: handler.flags)
      .then(in: context) { response -> Promise<WalletFlagsParser> in
        try self.persistenceManager.brokers.wallet.persistWalletResponse(from: response, in: context)
        return Promise.value(WalletFlagsParser(flags: response.flags))
      }
      .done { (parser: WalletFlagsParser) in
        if parser.walletVersion != .v2 && parser.walletDeactivated {
          let desc = """
          You have entered recovery words from a legacy DropBit wallet. We are upgrading all wallets to a new version
          of DropBit for enhanced security, lower transaction fees, and Lightning support. Please enter the new
          recovery words you were given upon upgrading, or create a new wallet.
          """.removingMultilineLineBreaks()
          let startOverAction = AlertActionConfiguration(title: "Start Over", style: .cancel, action: {
            self.persistenceManager.keychainManager.storeSynchronously(anyValue: nil, key: .walletWords)
            self.persistenceManager.keychainManager.storeSynchronously(anyValue: nil, key: .walletWordsV2)
            self.persistenceManager.keychainManager.storeSynchronously(anyValue: false, key: .walletWordsBackedUp)
            let controller = StartViewController.newInstance(delegate: self)
            self.navigationController.setViewControllers([controller], animated: true)
          })
          let alertViewModel = AlertControllerViewModel(title: "New Seed Words Required",
                                                        description: desc,
                                                        image: nil,
                                                        style: .alert,
                                                        actions: [startOverAction])
          let alert = self.alertManager.alert(from: alertViewModel)
          self.navigationController.topViewController()?.present(alert, animated: true)
        } else if parser.walletVersion != .v2 {
          let words = self.persistenceManager.brokers.wallet.walletWords()
          self.persistenceManager.keychainManager.storeSynchronously(anyValue: words, key: .walletWords)
          self.persistenceManager.keychainManager.storeSynchronously(anyValue: nil, key: .walletWordsV2)
          self.persistenceManager.keychainManager.storeSynchronously(anyValue: false, key: .walletWordsBackedUp)
          self.startSegwitUpgrade()
        } else {
          try context.performThrowingAndWait {
            try context.saveRecursively()
          }
        }
      }
      .asVoid()
  }

  func coordinator(_ coordinator: DeviceVerificationCoordinator, didVerify type: UserIdentityType, isInitialSetupFlow: Bool) {
    switch type {
    case .phone:
      analyticsManager.track(event: .phoneVerified, with: nil)
      analyticsManager.track(property: MixpanelProperty(key: .phoneVerified, value: true))
    case .twitter:
      analyticsManager.track(event: .twitterVerified, with: nil)
      analyticsManager.track(property: MixpanelProperty(key: .twitterVerified, value: true))
    }
    completeVerification(from: coordinator, userIdentityType: type, isInitialSetupFlow: isInitialSetupFlow)
  }

  func coordinatorSkippedPhoneVerification(_ coordinator: DeviceVerificationCoordinator) {
    analyticsManager.track(event: .skipPhoneVerification, with: nil)
    log.debug("Skipped verification")

    persistenceManager.keychainManager.storeSynchronously(anyValue: NSNumber(value: true), key: .skippedVerification)
    serialQueueManager.enqueueWalletSyncIfAppropriate(type: .comprehensive, policy: .skipIfSpecificOperationExists,
                                                      completion: nil, fetchResult: nil)
    childCoordinatorDidComplete(childCoordinator: coordinator)
    continueSetupFlow()
  }

  func didReceiveTwilioError(for phoneNumber: String, route: TwilioErrorRoute) {
    let parser = CKPhoneNumberParser()
    let e164 = "+" + phoneNumber

    guard let globalNumber = try? parser.parse(e164) else {
      log.error("Failed to parse phone number for Twilio error")
      return
    }

    log.error("Failed to send SMS to country code: \(String(globalNumber.countryCode)), route: \(route.rawValue)")

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
    guard let walletWorker = workerFactory().createWalletAddressDataWorker(delegate: self) else { return }
    let bgContext = persistenceManager.createBackgroundContext()
    let addressNumber = walletWorker.targetWalletAddressCount
    walletWorker.deleteAllAddressesOnServer()
      .then(in: bgContext) { walletWorker.registerAndPersistServerAddresses(number: addressNumber, in: bgContext) }
      .get(in: bgContext) { _ in
        try? bgContext.saveRecursively()
      }
      .catch(policy: .allErrors) { log.error($0, message: "failed to register wallet addresses") }
  }

  private func completeVerification(
    from coordinator: DeviceVerificationCoordinator,
    userIdentityType: UserIdentityType,
    isInitialSetupFlow: Bool) {

    let verifiedIdentities = persistenceManager.brokers.user.verifiedIdentities(in: persistenceManager.viewContext)
    if launchStateManager.profileIsActivated() && verifiedIdentities.count == 1 {
      log.debug("Profile is activated, will register wallet addresses")
      registerInitialWalletAddresses()
    }

    persistenceManager.keychainManager.storeSynchronously(anyValue: NSNumber(value: false), key: .skippedVerification)

    serialQueueManager.enqueueWalletSyncIfAppropriate(type: .comprehensive, policy: .skipIfSpecificOperationExists,
                                                      completion: nil, fetchResult: nil)
    childCoordinatorDidComplete(childCoordinator: coordinator)
    continueSetupFlow()
    let desc = userIdentityType.identityDescription
    alertManager.showBanner(
      with: "Your \(desc) has been successfully verified. You can now send DropBits to your \(userIdentityType.displayDescription) contacts.",
      duration: .custom(5))

    if !isInitialSetupFlow {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.presentDropBitMeViewController(verifiedFirstTime: true)
      }
    }
  }
}
