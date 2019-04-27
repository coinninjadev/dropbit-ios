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

  let currencyController: CurrencyController

  private let maxSecondsInBackground: TimeInterval = 30
  private let notificationLogger = OSLog(subsystem: "com.coinninja.appCoordinator", category: "notifications")
  let phoneNumberKit = PhoneNumberKit()
  let contactStore = CNContactStore()

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

    setCurrentCoin()

    self.networkManager.headerDelegate = self
    self.networkManager.walletDelegate = self
    self.alertManager.urlOpener = self
    self.serialQueueManager.delegate = self
  }

  func badgingManager() -> BadgeManagerType {
    return badgeManager
  }

  /// This function ensures we are always working with the current instance of the WalletManager
  func createTransactionDataWorker() -> TransactionDataWorker? {
    guard let wmgr = walletManager else { return nil }
    return TransactionDataWorker(walletManager: wmgr,
                                 persistenceManager: persistenceManager,
                                 networkManager: networkManager,
                                 analyticsManager: analyticsManager)
  }

  /// This function ensures we are always working with the current instance of the WalletManager
  func createWalletAddressDataWorker() -> WalletAddressDataWorker? {
    guard let wmgr = walletManager else { return nil }
    return WalletAddressDataWorker(walletManager: wmgr,
                                   persistenceManager: persistenceManager,
                                   networkManager: networkManager,
                                   analyticsManager: analyticsManager,
                                   phoneNumberKit: self.phoneNumberKit,
                                   invitationWorkerDelegate: self)
  }

  func createDatabaseMigrationWorker(in context: NSManagedObjectContext) -> DatabaseMigrationWorker? {
    guard let factory = createMigratorFactory(in: context) else { return nil }
    let migrators = factory.migrators()
    return DatabaseMigrationWorker(migrators: migrators, in: context)
  }

  func createKeychainMigrationWorker() -> KeychainMigrationWorker {
    let factory = KeychainMigratorFactory(persistenceManager: persistenceManager)
    return KeychainMigrationWorker(migrators: factory.migrators())
  }

  func createContactCacheMigrationWorker() -> ContactCacheMigrationWorker {
    let factory = ContactCacheMigratorFactory(persistenceManager: persistenceManager,
                                              dataWorker: contactCacheDataWorker)
    return ContactCacheMigrationWorker(migrators: factory.migrators())
  }

  func createMigratorFactory(in context: NSManagedObjectContext) -> DatabaseMigratorFactory? {
    guard let wmgr = walletManager else { return nil }
    let addressDataSource = wmgr.createAddressDataSource()
    return DatabaseMigratorFactory(persistenceManager: persistenceManager, addressDataSource: addressDataSource, context: context)
  }

  func registerForRemoteNotifications(with deviceToken: Data) {
    let token = deviceToken.hexString
    persistenceManager.set(token, for: .devicePushToken)

    notificationManager.performRegistrationIfNeeded(forPushToken: token)
  }

  private func requestPushNotificationDialogueIfNeeded() {
    switch permissionManager.permissionStatus(for: .notification) {
    case .authorized:
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    case .disabled, .denied:
      notificationManager.removeSubscriptions()
    case .notDetermined:
      showPushNotificationActionableAlert()
    }
  }

  private func showPushNotificationActionableAlert() {
    let requestConfiguration = AlertActionConfiguration(title: "GOT IT", style: .default, action: { [weak self] in
      self?.permissionManager.requestPermission(for: .notification) { status in
        switch status {
        case .authorized:
          DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
          }
        default:
          break
        }
      }
    })

    let title = "Push notifications are an important part of the DropBit experience." +
    " Without them you will not be notified to complete transactions which will cause them to expire."

    let description = "Please allow us to send you push notifications on the following prompt."
    let alert = alertManager.detailedAlert(withTitle: title, description: description, image: #imageLiteral(resourceName: "dropBitBadgeIcon"), style: .warning, action: requestConfiguration)

    navigationController.topViewController()?.present(alert, animated: true)
  }

  var isReadyToEnterApp: Bool {
    return launchStateManager.deviceIsVerified() || launchStateManager.skippedVerification
  }

  var isFirstTimeOpeningApp: Bool {
    return !persistenceManager.bool(for: .firstTimeOpeningApp)
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
    } else if isReadyToEnterApp {

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
      if launchStateManager.shouldRegisterWallet(),
        launchStateManager.nextLaunchStep == .verifyDevice {

        // StartViewController is the default root VC
        // Child coordinator will push DeviceVerificationViewController onto stack in its start() method
        startDeviceVerificationFlow(shouldOrphanRoot: true)
      } else if launchStateManager.isFirstTime() {
        startNewWalletFlow()
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

  private func startNewWalletFlow() {
    let startVC = StartViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: startVC)
    navigationController.viewControllers = [startVC]
  }

  func viewController(_ viewController: UIViewController, didSkipBackingUp words: [String], flow: RecoveryWordsFlow) {
    let backupNowConfig = AlertActionConfiguration(title: "Back up now", style: .cancel, action: nil)
    let skipConfig = AlertActionConfiguration(title: "OK, skip", style: .default) {
      self.saveSuccessfulWords(words: words, isBackedUp: false, flow: flow)
      self.continueNavigation(with: viewController, for: flow)
    }
    let title = "You will have restricted use of the DropBit features until your wallet" +
    " is backed up. Please backup as soon as you are able."
    let alert = alertManager.alert(withTitle: title, description: nil, image: nil, style: .alert, actionConfigs: [backupNowConfig, skipConfig])
    navigationController.topViewController()?.present(alert, animated: true)
  }

  func continueNavigation(with viewController: UIViewController, for flow: RecoveryWordsFlow) {
    switch flow {
    case .settings:
      viewController.dismiss(animated: true, completion: nil)
    case .createWallet:
      continueCreateWalletFlow()
    }
  }

  func trackWordsBackedUp(_ isBackedUp: Bool) {
    let wordsBackupEventType: AnalyticsManagerEventType = isBackedUp ? .wordsBackedup : .skipWordsBackedup
    analyticsManager.track(event: wordsBackupEventType, with: nil)
  }

  private func continueCreateWalletFlow() {
    analyticsManager.track(event: .createWallet, with: nil)
    continueSetupFlow()
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
    trackIfUserHasWallet()
    trackIfUserHasWordsBackedUp()
    trackEventForFirstTimeOpeningAppIfApplicable()
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

  private func trackEventForFirstTimeOpeningAppIfApplicable() {
    if isFirstTimeOpeningApp {
      analyticsManager.track(event: .firstOpen, with: nil)
      persistenceManager.set(true, for: .firstTimeOpeningApp)
    }
  }

  private func trackIfUserHasWallet() {
    if walletManager == nil {
      analyticsManager.track(property: MixpanelProperty(key: .hasWallet, value: false))
    } else {
      analyticsManager.track(property: MixpanelProperty(key: .hasWallet, value: true))
    }
  }

  private func trackIfUserHasWordsBackedUp() {
    if walletManager == nil || !wordsBackedUp {
      analyticsManager.track(property: MixpanelProperty(key: .wordsBackedUp, value: false))
    } else {
      analyticsManager.track(property: MixpanelProperty(key: .wordsBackedUp, value: true))
    }
  }

  func trackIfUserHasABalance() {
    let bgContext = persistenceManager.createBackgroundContext()
    guard let wmgr = walletManager else {
      self.analyticsManager.track(property: MixpanelProperty(key: .hasBTCBalance, value: false))
      return
    }

    var balanceIsPositive = false
    bgContext.performAndWait {
      balanceIsPositive = wmgr.spendableBalance(in: bgContext) > 0
    }

    analyticsManager.track(property: MixpanelProperty(key: .hasBTCBalance, value: balanceIsPositive ? true : false))
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

  var drawerController: MMDrawerController? {
    return navigationController.topViewController.flatMap { $0 as? MMDrawerController }
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

  private func checkForWordsBackedUp() {
    let isBackedUp = launchStateManager.walletIsBackedUp()
    let backupWordsReminderShown = persistenceManager.bool(for: .backupWordsReminderShown)
    guard !isBackedUp && !backupWordsReminderShown else { return }
    let title = "Remember to backup your wallet to ensure your Bitcoin is secure in case your phone" +
    " is ever lost or stolen. Tap here to backup now."
    alertManager.showBanner(with: title, duration: nil, alertKind: .error) { [weak self] in
      self?.analyticsManager.track(event: .backupWordsButtonPressed, with: nil)
      self?.showWordRecoveryFlow()
    }
    persistenceManager.set(true, for: .backupWordsReminderShown)
  }

  private func registerWalletWithServerIfNeeded(completion: @escaping () -> Void) {
    if launchStateManager.shouldRegisterWallet() {
      registerWallet(completion: completion)
    } else {
      completion()
    }
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

    // check keychain time interval for resigned time, and if within 30 sec, don't require
    let now = Date().timeIntervalSince1970
    let lastLogin = persistenceManager.lastLoginTime() ?? Date.distantPast.timeIntervalSince1970

    analyticsManager.track(event: .appOpen, with: nil)

    let secondsSinceLastLogin = now - lastLogin
    if secondsSinceLastLogin > maxSecondsInBackground {
      dismissAllModalViewControllers()
      resetUserAuthenticatedState()
      requireAuthenticationIfNeeded(whenAuthenticated: {
        self.continueSetupFlow()
      })
    }

    refreshContacts()
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

  func continueSetupFlow() {
    switch launchStateManager.nextLaunchStep {
    case .enterPin:       startFirstTimeWalletCreationFlow()
    case .createWallet:   startCreateRecoveryWordsFlow()
    case .verifyDevice:   startDeviceVerificationFlow(shouldOrphanRoot: true)
    case .enterApp: validToStartEnteringApp()
    case .phoneRestore: startFirstTimeAfteriCloudRestore()
    }
  }

  func startCreateRecoveryWordsFlow(animated: Bool = true) {
    func performFunction() {
      let words = WalletManager.createMnemonicWords()
      self.saveSuccessfulWords(words: words, isBackedUp: false, flow: .createWallet)
      self.continueCreateWalletFlow()
    }

    guard !launchStateManager.shouldRequireAuthentication else {
      requireAuthenticationIfNeeded(whenAuthenticated: performFunction)
      return
    }
    guard let topVC = navigationController.topViewController,
      !(topVC is CreateRecoveryWordsViewController) else { return }

    performFunction()
  }

  func saveSuccessfulWords(words: [String], isBackedUp: Bool = true, flow: RecoveryWordsFlow) {
    trackWordsBackedUp(isBackedUp)

    switch flow {
    case .createWallet:
      guard persistenceManager.keychainManager.store(recoveryWords: words) else {
        fatalError("Failed to write recovery words to keychain")
      }
      walletManager = WalletManager(words: words, persistenceManager: persistenceManager)
    case .settings:
      persistenceManager.backup(recoveryWords: words)
    }

    //This wouldn't be called when we allow them to set up a wallet without backing up their words
    //Important to store boolean as NSNumber for the keychain
    guard persistenceManager.keychainManager.store(anyValue: NSNumber(value: isBackedUp), key: .walletWordsBackedUp) else {
      fatalError("Failed to write status to keychain for walletWordsBackedUp")
    }
  }

  func startDeviceVerificationFlow(shouldOrphanRoot: Bool) {
    func performFunction() {

      let childCoordinator = DeviceVerificationCoordinator(navigationController, shouldOrphanRoot: shouldOrphanRoot)
      startChildCoordinator(childCoordinator: childCoordinator)
    }

    guard !launchStateManager.shouldRequireAuthentication else {
      requireAuthenticationIfNeeded(whenAuthenticated: performFunction)
      return
    }
    guard let topVC = navigationController.topViewController,
      !(topVC is DeviceVerificationViewController) else { return }

    performFunction()
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

  private func startFirstTimeWalletCreationFlow() {
    let viewController = PinCreationViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: viewController)
    navigationController.pushViewController(viewController, animated: true)
  }

  private func startFirstTimeAfteriCloudRestore() {
    let title = ""
    let description = "It looks like you have restored from a backup. Please enter your 12 recovery words to restore your wallet."
    let okAction = AlertActionConfiguration(title: "RESTORE NOW", style: .default) { self.restoreWallet() }
    let alertViewModel = AlertControllerViewModel(title: title, description: description, actions: [okAction])
    let alert = alertManager.alert(from: alertViewModel)
    navigationController.topViewController()?.present(alert, animated: true)
  }
}
