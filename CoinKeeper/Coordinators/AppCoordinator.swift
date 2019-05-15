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

// swiftlint:disable file_length
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

// swiftlint:disable type_body_length
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
  let uiTestArguments: [UITestArgument]

  // swiftlint:disable:next weak_delegate
  let mailComposeDelegate = MailerDelegate()
  // swiftlint:disable:next weak_delegate
  let messageComposeDelegate = MessagerDelegate()
  // swiftlint:disable:next weak_delegate
  let locationDelegate = LocationManagerDelegate()

  let currencyController: CurrencyController

  private let maxSecondsInBackground: TimeInterval = 30

  /// Assign a future date and upon app open, this will skip the need
  /// for authentication (only once), up until the specified date.
  var suspendAuthenticationOnceUntil: Date?

  private let notificationLogger = OSLog(subsystem: "com.coinninja.appCoordinator", category: "notifications")
  let phoneNumberKit = PhoneNumberKit()
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
    uiTestArguments: [UITestArgument] = []
    ) {
    currencyController.selectedCurrency = persistenceManager.selectedCurrency()
    self.currencyController = currencyController

    self.navigationController = navigationController
    self.serialQueueManager = serialQueueManager
    self.persistenceManager = persistenceManager
    self.biometricsAuthenticationManager = biometricsAuthenticationManager
    let theLaunchStateManager = launchStateManager ?? LaunchStateManager(persistenceManager: persistenceManager)
    self.launchStateManager = theLaunchStateManager
    self.badgeManager = BadgeManager(persistenceManager: persistenceManager)
    self.analyticsManager = analyticsManager
    if let words = persistenceManager.walletWords() {
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
        startDeviceVerificationFlow(shouldOrphanRoot: true, isInitialSetupFlow: true)
      } else if launchStateManager.isFirstTime() {
        let startVC = StartViewController.makeFromStoryboard()
        assignCoordinationDelegate(to: startVC)
        navigationController.viewControllers = [startVC]
      }
    }
  }

  private func validToStartEnteringApp() {
    enterApp()
    checkForBackendMessages()
    checkForWordsBackedUp()
    requestPushNotificationDialogueIfNeeded()
    configureBadgeTopics()
  }

  private func configureBadgeTopics() {
    let topics: [BadgeTopic] = [
      UnverifiedPhoneBadgeTopic(),
      WordsNotBackedUpBadgeTopic()
    ]
    topics.forEach { badgeManager.add(topic: $0) }
    badgeManager.publishBadgeUpdate()
  }

  func registerWallet(completion: @escaping () -> Void) {
    let bgContext = persistenceManager.createBackgroundContext()
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "register_wallet")
    bgContext.perform {
      self.registerAndPersistWallet(in: bgContext).asVoid()
        .done(on: .main) { completion() }
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

    setInitialRootViewController()

    // fetch transaction information for receive and change addresses, update server addresses
    registerForBalanceSaveNotifications()
    trackAnalytics()
    UIApplication.shared.setMinimumBackgroundFetchInterval(.oneHour)

    let now = Date()
    let lastContactReloadDate: Date = persistenceManager.date(for: .lastContactCacheReload) ?? .distantPast
    let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
    let shouldForce = lastContactReloadDate < oneWeekAgo
    self.contactCacheDataWorker.reloadSystemContactsIfNeeded(force: shouldForce) { [weak self] _ in
      self?.persistenceManager.matchContactsIfPossible()
      if shouldForce {
        self?.persistenceManager.set(now, for: .lastContactCacheReload)
      }
    }
  }

  private func applyUITestArguments(_ arguments: [UITestArgument]) {
    if arguments.isEmpty { return }

    if uiTestArguments.contains(.resetPersistence) {
      persistenceManager.resetPersistence()
      walletManager = nil
    }

    if uiTestArguments.contains(.skipGlobalMessageDisplay) {
      messageManager.setShouldShowGlobalMessaging(false)
    }
  }

  func startChildCoordinator(childCoordinator: ChildCoordinatorType) {
    childCoordinators.append(childCoordinator)
    childCoordinator.delegate = self
    childCoordinator.start()
  }

  func enterApp() {
    let mainViewController = makeTransactionHistory()
    let settingsViewController = DrawerViewController.makeFromStoryboard()
    let drawerController = setupDrawerViewController(centerViewController: mainViewController,
                                                     leftViewController: settingsViewController)
    assignCoordinationDelegate(to: settingsViewController)
    navigationController.popToRootViewController(animated: false)
    navigationController.viewControllers = [drawerController]

    navigationController.isNavigationBarHidden = true

    handlePendingBitcoinURL()
  }

  private func handlePendingBitcoinURL() {
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

  private func checkForBackendMessages() {
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "messages")
    networkManager.queryForMessages()
      .done { (responses: [MessageResponse]) in
        self.messageManager.showNewAndCache(responses)
      }.catch(policy: .allErrors) { os_log("failed to show messages: %@",
                                           log: logger,
                                           type: .error, $0.localizedDescription) }
  }

  private func setupDrawerViewController(centerViewController: UIViewController, leftViewController: UIViewController) -> MMDrawerController {
    let drawerWidth: CGFloat = 118.0
    let drawerController = MMDrawerController(center: centerViewController,
                                              leftDrawerViewController: leftViewController)
    drawerController?.setMaximumLeftDrawerWidth(drawerWidth, animated: false, completion: nil)
    drawerController?.closeDrawerGestureModeMask = [.tapCenterView, .tapNavigationBar]
    drawerController?.showsShadow = false
    return drawerController!
  }

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
      dismissAllModalViewControllers()
      resetUserAuthenticatedState()
      requireAuthenticationIfNeeded(whenAuthenticated: {
        self.continueSetupFlow()
      })
    }
  }

  func resetWalletManagerIfNeeded() {
    if walletManager == nil,
      let words = persistenceManager.walletWords() {
      walletManager = WalletManager(words: words, persistenceManager: persistenceManager)
    }
    setCurrentCoin()
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

  private func refreshContacts() {
    let contactCacheMigrationWorker = createContactCacheMigrationWorker()
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

  var wordsBackedUp: Bool {
    return launchStateManager.walletIsBackedUp()
  }

  func requireAuthenticationIfNeeded(whenAuthenticated: (() -> Void)?) {
    connectionManager.delegate?.connectionManager(connectionManager, didChangeStatusTo: connectionManager.status)
    guard launchStateManager.shouldRequireAuthentication,
      !(navigationController.topViewController()?.isKind(of: PinEntryViewController.classForCoder()) ?? true)
      else { return }

    let pinEntryVC = PinEntryViewController.makeFromStoryboard()
    // This closure is called by its delegate's implementation of viewControllerDidSuccessfullyAuthenticate()
    pinEntryVC.whenAuthenticated = whenAuthenticated
    assignCoordinationDelegate(to: pinEntryVC)

    pinEntryVC.modalPresentationStyle = .overCurrentContext
    pinEntryVC.modalTransitionStyle = .crossDissolve
    navigationController.setViewControllers([pinEntryVC], animated: false)
  }

  private func dismissAllModalViewControllers() {
    UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: false, completion: nil)
  }

  private func setCurrentCoin() {
    let isTestnet = UserDefaults.standard.bool(forKey: "ontestnet")
    let coin: CNBBaseCoin = isTestnet ? BTCTestnetCoin() : BTCMainnetCoin()
    walletManager?.coin = coin
  }

  func showScanViewController(fallbackBTCAmount: NSDecimalNumber, primaryCurrency: CurrencyCode) {
    let scanViewController = ScanQRViewController.makeFromStoryboard()
    scanViewController.fallbackPaymentViewModel = SendPaymentViewModel(btcAmount: fallbackBTCAmount, primaryCurrency: primaryCurrency)

    assignCoordinationDelegate(to: scanViewController)
    scanViewController.modalPresentationStyle = .formSheet
    navigationController.present(scanViewController, animated: true, completion: nil)
  }

  func makeTransactionHistory() -> TransactionHistoryViewController {
    let txHistory = TransactionHistoryViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: txHistory)
    txHistory.context = persistenceManager.mainQueueContext()
    txHistory.balanceProvider = self
    txHistory.balanceDelegate = self
    txHistory.urlOpener = self
    return txHistory
  }

  /// This may fail with a 500 error if the addresses were already added during a previous installation of the same wallet
  func registerInitialWalletAddresses() {
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

  /// Show the recovery word backup flow.
  ///
  /// - Parameter words: If no parameter is passed in, the default behavior will search the keychain for stored words. Ensure 12 words are passed in.
  func showWordRecoveryFlow(with words: [String] = []) {
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "show_recovery")
    guard let wmgr = walletManager else {
      os_log("WalletManager is nil in %@", log: logger, type: .error, #function)
      return }

    let usableWords = words.isEmpty ? wmgr.mnemonicWords() : []

    guard usableWords.count == 12 else {
      os_log("Failed to receive 12 words in %@", log: logger, type: .error, #function)
      return
    }

    let recoveryWordsIntroViewController = RecoveryWordsIntroViewController.makeFromStoryboard()
    recoveryWordsIntroViewController.flow = .settings
    recoveryWordsIntroViewController.recoveryWords = usableWords
    assignCoordinationDelegate(to: recoveryWordsIntroViewController)
    navigationController.present(CNNavigationController(rootViewController: recoveryWordsIntroViewController),
                                 animated: false,
                                 completion: nil)
  }

  func createPinEntryViewControllerForRecoveryWords(_ words: [String]) -> PinEntryViewController {
    let pinEntryViewController = PinEntryViewController.makeFromStoryboard()
    pinEntryViewController.mode = .recoveryWords(completion: { _ in
      let wordsViewController = CreateRecoveryWordsViewController.makeFromStoryboard()
      wordsViewController.flow = .settings
      wordsViewController.recoveryWords = words
      wordsViewController.wordsBackedUp = self.wordsBackedUp
      self.analyticsManager.track(event: .viewWords, with: nil)
      self.assignCoordinationDelegate(to: wordsViewController)
      self.navigationController.present(CNNavigationController(rootViewController: wordsViewController), animated: false, completion: nil)
    })
    assignCoordinationDelegate(to: pinEntryViewController)

    return pinEntryViewController
  }

  func viewControllerDidRequestBadgeUpdate(_ viewController: UIViewController) {
    badgeManager.publishBadgeUpdate()
  }

  // MARK: private methods
  private func insufficientBalanceDetails(for error: PendingInvitationError) -> (id: String, message: String)? {
    switch error {
    case .insufficientFundsForInvitationWithID(let id):
      let message = "Insufficient funds. A \(CKStrings.dropBitWithTrademark) you attempted to send is for more Bitcoin than you currently have."
      return (id, message)

    case .insufficientFeeForInvitationWithID(let id):
      let message = "Insufficient fees. The \(CKStrings.dropBitWithTrademark) will be canceled and you can re-send your DropBit with current fees."
      return (id, message)
    default:
      return nil
    }
  }

}
