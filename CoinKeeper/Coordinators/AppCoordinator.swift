//
//  AppCoordinator.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import CNBitcoinKit
import MMDrawerController
import Moya
import Permission
import AVFoundation
import PromiseKit
import CoreData
import CoreLocation
import os.log
import PhoneNumberKit
import MessageUI
import Contacts

protocol CoordinatorType: class {
  func start()
}

extension CoordinatorType {
  func assignCoordinationDelegate(to viewController: UIViewController) {
    (viewController as? Coordination)?.generalCoordinationDelegate = self
  }
}

protocol ChildCoordinatorType: CoordinatorType {
  var delegate: ChildCoordinatorDelegate? { get set }
}

protocol ChildCoordinatorDelegate: class {
  func childCoordinatorDidComplete(childCoordinator: ChildCoordinatorType)
}

let phoneNumberKit = PhoneNumberKit()

class AppCoordinator: CoordinatorType {
  let navigationController: UINavigationController
  let persistenceManager: PersistenceManagerType
  let biometricsAuthenticationManager: BiometricAuthenticationManagerType
  let launchStateManager: LaunchStateManagerType
  var walletManager: WalletManagerType?
  let balanceUpdateManager: BalanceUpdateManager
  let alertManager: AlertManagerType
  let badgeManager: BadgeManagerType
  let analyticsManager: AnalyticsManagerType
  let serialQueueManager: SerialQueueManagerType
  let permissionManager: PermissionManagerType
  let networkManager: NetworkManagerType
  let connectionManager: ConnectionManagerType
  var childCoordinators: [ChildCoordinatorType] = []
  let notificationManager: NotificationManagerType
  let messageManager: MessagesManagerType
  let persistenceCacheDataWorker: PersistenceCacheDataWorkerType
  let twitterAccessManager: TwitterAccessManagerType
  let uiTestArguments: [UITestArgument]

  // swiftlint:disable:next weak_delegate
  let mailComposeDelegate = MailerDelegate()
  // swiftlint:disable:next weak_delegate
  let messageComposeDelegate = MessagerDelegate()
  // swiftlint:disable:next weak_delegate
  let locationDelegate = LocationManagerDelegate()

  let currencyController: CurrencyController

  let maxSecondsInBackground: TimeInterval = 30

  /// Assign a future date and upon app open, this will skip the need
  /// for authentication (only once), up until the specified date.
  var suspendAuthenticationOnceUntil: Date?

  private let notificationLogger = OSLog(subsystem: "com.coinninja.appCoordinator", category: "notifications")
  let contactStore = CNContactStore()
  let locationManager = CLLocationManager()

  var bitcoinURLToOpen: BitcoinURL?

  lazy var contactCacheDataWorker: ContactCacheDataWorker = {
    return ContactCacheDataWorker(contactCacheManager: self.contactCacheManager,
                                  permissionManager: self.permissionManager,
                                  userRequester: self.networkManager,
                                  contactStore: self.contactStore,
                                  countryCodeProvider: self.persistenceManager)
  }()

  lazy var workerFactory: WorkerFactory = {
    return WorkerFactory(persistenceManager: self.persistenceManager,
                         networkManager: self.networkManager,
                         analyticsManager: self.analyticsManager,
                         walletManagerProvider: self)
  }()

  init(
    navigationController: CNNavigationController = CNNavigationController(),
    persistenceManager: PersistenceManagerType = PersistenceManager(),
    biometricsAuthenticationManager: BiometricAuthenticationManagerType = BiometricAuthenticationManager(),
    launchStateManager: LaunchStateManagerType? = nil,
    walletManager: WalletManagerType? = nil,
    alertManager: AlertManagerType? = nil,
    badgeManager: BadgeManagerType? = nil,
    networkManager: NetworkManagerType? = nil,
    permissionManager: PermissionManagerType = PermissionManager(),
    analyticsManager: AnalyticsManagerType = AnalyticsManager(),
    connectionManager: ConnectionManagerType = ConnectionManager(),
    serialQueueManager: SerialQueueManagerType = SerialQueueManager(),
    notificationManager: NotificationManagerType? = nil,
    messageManager: MessagesManagerType? = nil,
    currencyController: CurrencyController = CurrencyController(currentCurrencyCode: .USD),
    twitterAccessManager: TwitterAccessManagerType? = nil,
    uiTestArguments: [UITestArgument] = []
    ) {
    currencyController.selectedCurrency = persistenceManager.brokers.preferences.selectedCurrency
    self.currencyController = currencyController

    self.navigationController = navigationController
    self.serialQueueManager = serialQueueManager
    self.persistenceManager = persistenceManager
    self.biometricsAuthenticationManager = biometricsAuthenticationManager
    let theLaunchStateManager = launchStateManager ?? LaunchStateManager(persistenceManager: persistenceManager)
    self.launchStateManager = theLaunchStateManager
    self.badgeManager = BadgeManager(persistenceManager: persistenceManager)
    self.analyticsManager = analyticsManager
    if let words = persistenceManager.brokers.wallet.walletWords() {
      self.walletManager = WalletManager(words: words, persistenceManager: persistenceManager)
    }
    self.balanceUpdateManager = BalanceUpdateManager()
    let theNetworkManager = networkManager ?? NetworkManager(persistenceManager: persistenceManager,
                                                             analyticsManager: analyticsManager)
    self.networkManager = theNetworkManager
    self.permissionManager = permissionManager
    self.connectionManager = connectionManager

    self.uiTestArguments = uiTestArguments

    self.persistenceCacheDataWorker = PersistenceCacheDataWorker(persistenceManager: persistenceManager, analyticsManager: analyticsManager)

    let twitterMgr = twitterAccessManager ?? TwitterAccessManager(networkManager: theNetworkManager, persistenceManager: persistenceManager)
    self.twitterAccessManager = twitterMgr

    let notificationMgr = notificationManager ?? NotificationManager(permissionManager: permissionManager, networkInteractor: theNetworkManager)
    let alertMgr = alertManager ?? AlertManager(notificationManager: notificationMgr)
    self.alertManager = alertMgr
    self.messageManager = MessageManager(alertManager: alertMgr, persistenceManager: persistenceManager)
    self.notificationManager = notificationMgr
    self.notificationManager.delegate = self
    self.locationManager.delegate = self.locationDelegate

    setCurrentCoin()

    self.networkManager.headerDelegate = self
    self.networkManager.walletDelegate = self
    self.alertManager.urlOpener = self
    self.serialQueueManager.delegate = self
  }

  var drawerController: MMDrawerController? {
    return navigationController.topViewController.flatMap { $0 as? MMDrawerController }
  }

  private func setInitialRootViewController() {
    deleteStaleCredentialsIfNeeded()

    if launchStateManager.isFirstTimeAfteriCloudRestore() {
      startFirstTimeAfteriCloudRestore()
    } else if launchStateManager.shouldRequireAuthentication {
      registerWalletWithServerIfNeeded {
        self.requireAuthenticationIfNeeded {
          self.continueSetupFlow()
        }
      }
    } else if verificationSatisfied {

      // If user previously skipped registering the device and reinstalled,
      // the skipped state is still in the keychain but the wallet needs to be registered again.
      // Otherwise, they can enter the app directly.
      registerWalletWithServerIfNeeded {
        self.validToStartEnteringApp()
      }

    } else {

      navigationController.topViewController.flatMap { self.assignCoordinationDelegate(to: $0) }

      // Take user directly to phone verification if wallet exists but wallet ID does not
      // This will register the wallet if needed after a reinstall
      let launchProperties = launchStateManager.currentProperties()
      if launchStateManager.shouldRegisterWallet(),
        launchProperties.contains(.pinExists) {

        // StartViewController is the default root VC
        // Child coordinator will push DeviceVerificationViewController onto stack in its start() method
        startDeviceVerificationFlow(userIdentityType: .phone, shouldOrphanRoot: true, selectedSetupFlow: .newWallet)
      } else if launchStateManager.isFirstTime() {
        let startVC = StartViewController.makeFromStoryboard()
        assignCoordinationDelegate(to: startVC)
        navigationController.viewControllers = [startVC]
      }
    }
  }

  /// Useful to clear out old credentials from the keychain when the app is reinstalled
  private func deleteStaleCredentialsIfNeeded() {
    let context = persistenceManager.mainQueueContext()
    let user = CKMUser.find(in: context)
    guard user == nil else { return }

    let twitterCredsExist = persistenceManager.keychainManager.oauthCredentials() != nil
    if twitterCredsExist {
      persistenceManager.keychainManager.unverifyUser(for: .twitter)
    }

    let phoneExists = persistenceManager.brokers.user.verifiedPhoneNumber() != nil
    if phoneExists {
      persistenceManager.keychainManager.unverifyUser(for: .phone)
    }
  }

  func validToStartEnteringApp() {
    launchStateManager.selectedSetupFlow = nil
    enterApp()
    checkForBackendMessages()
    checkForWordsBackedUp()
    requestPushNotificationDialogueIfNeeded()
    badgeManager.setupTopics()
  }

  func setWalletManagerWithPersistedWords() {
    if let words = self.persistenceManager.brokers.wallet.walletWords() {
      self.walletManager = WalletManager(words: words, persistenceManager: self.persistenceManager)
    }
  }

  func registerWallet(completion: @escaping () -> Void) {
    let bgContext = persistenceManager.createBackgroundContext()
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "register_wallet")
    bgContext.perform {
      self.registerAndPersistWallet(in: bgContext)
        .done(in: bgContext) {
          try bgContext.save()
          DispatchQueue.main.async {
            completion()
          }
        }
        .catch { os_log("failed to register and persist wallet: %@", log: logger, type: .error, $0.localizedDescription) }
    }
  }

  func start() {
    (navigationController.topViewController as? BaseViewController).map { self.assignCoordinationDelegate(to: $0) }
    applyUITestArguments(uiTestArguments)
    analyticsManager.start()
    analyticsManager.optIn()
    networkManager.start()
    connectionManager.delegate = self

    // fetch transaction information for receive and change addresses, update server addresses
    UIApplication.shared.setMinimumBackgroundFetchInterval(.oneHour)

    guard UIApplication.shared.applicationState != .background else { return }

    setInitialRootViewController()
    registerForBalanceSaveNotifications()
    trackAnalytics()

    let now = Date()
    let lastContactReloadDate: Date = persistenceManager.brokers.activity.lastContactCacheReload ?? .distantPast
    let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
    let shouldForce = lastContactReloadDate < oneWeekAgo
    self.contactCacheDataWorker.reloadSystemContactsIfNeeded(force: shouldForce) { [weak self] _ in
      self?.persistenceManager.matchContactsIfPossible()
      if shouldForce {
        self?.persistenceManager.brokers.activity.lastContactCacheReload = now
      }
    }
  }

  private func applyUITestArguments(_ arguments: [UITestArgument]) {
    if arguments.isEmpty { return }

    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "UI_Test_Arguments")
    if uiTestArguments.contains(.resetPersistence) {
      do {
        try persistenceManager.resetPersistence()
        walletManager = nil
      } catch {
        os_log("Failed to reset persistence in %@, error: %@", log: logger, type: .error, #function, error.localizedDescription)
      }
    }

    if uiTestArguments.contains(.skipGlobalMessageDisplay) {
      messageManager.setShouldShowGlobalMessaging(false)
    }

    twitterAccessManager.uiTestArguments = uiTestArguments
  }

  func startChildCoordinator(childCoordinator: ChildCoordinatorType) {
    childCoordinators.append(childCoordinator)
    childCoordinator.delegate = self
    childCoordinator.start()
  }

  /// Handle app becoming active
  func appEnteredActiveState() {
    resetWalletManagerIfNeeded()
    connectionManager.start()

    analyticsManager.track(event: .appOpen, with: nil)

    authenticateOnBecomingActiveIfNeeded()

    refreshTwitterAvatar()
    refreshContacts()
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
  func appWillResignActiveState() {
    let backgroundTaskId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
    connectionManager.stop()
    persistenceManager.brokers.activity.setLastLoginTime()
    UIApplication.shared.endBackgroundTask(backgroundTaskId)
  }

  private func authenticateOnBecomingActiveIfNeeded() {
    defer { self.suspendAuthenticationOnceUntil = nil }
    if let suspendUntil = self.suspendAuthenticationOnceUntil, suspendUntil > Date() {
      return
    }

    // check keychain time interval for resigned time, and if within 30 sec, don't require
    let now = Date().timeIntervalSince1970
    let lastLogin = persistenceManager.brokers.activity.lastLoginTime ?? Date.distantPast.timeIntervalSince1970

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

  private func refreshTwitterAvatar() {
    let bgContext = persistenceManager.createBackgroundContext()
    bgContext.performAndWait {
      guard persistenceManager.brokers.user.userIsVerified(using: .twitter, in: bgContext) else {
        return
      }

      twitterAccessManager.refreshTwitterAvatar(in: bgContext)
        .done(on: .main) { didChange in
          if didChange {
            CKNotificationCenter.publish(key: .didUpdateAvatar)
          }
        }.cauterize()
    }
  }

  private func checkForBackendMessages() {
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "messages")
    networkManager.queryForMessages()
      .done { (responses: [MessageResponse]) in
        self.messageManager.showNewAndCache(responses)
      }.catch(policy: .allErrors) { os_log("failed to show messages: %@",
                                           log: logger,
                                           type: .error, $0.localizedDescription) }
  }

  func refreshContacts() {
    let contactCacheMigrationWorker = workerFactory.createContactCacheMigrationWorker(dataWorker: contactCacheDataWorker)
    _ = contactCacheMigrationWorker.migrateIfPossible()
      .done {
        self.contactCacheDataWorker.reloadSystemContactsIfNeeded(force: false) { [weak self] _ in
          self?.persistenceManager.matchContactsIfPossible()
        }
    }
  }

  func resetUserAuthenticatedState() {
    biometricsAuthenticationManager.resetPolicy()
    launchStateManager.unauthenticateUser()
  }

  func setCurrentCoin() {
    let isTestnet = UserDefaults.standard.bool(forKey: "ontestnet")
    let coin: CNBBaseCoin = isTestnet ? BTCTestnetCoin() : BTCMainnetCoin()
    walletManager?.coin = coin
  }

}
