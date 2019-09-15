//
//  AppCoordinator+SetupFlows.swift
//  DropBit
//
//  Created by Ben Winters on 5/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
import UIKit
import MMDrawerController
import CoreData

enum SetupFlow {
  case newWallet
  case restoreWallet
  case claimInvite(method: UserIdentityType?) //associated value should be nil until user selects invite method
}

extension AppCoordinator {

  var wordsBackedUp: Bool {
    return launchStateManager.walletIsBackedUp()
  }

  var verificationSatisfied: Bool {
    return launchStateManager.deviceIsVerified() || launchStateManager.skippedVerification
  }

  func enterApp() {
    let overviewViewController = makeOverviewController()
    let settingsViewController = DrawerViewController.newInstance(delegate: self)
    let drawerController = setupDrawerViewController(centerViewController: overviewViewController,
                                                     leftViewController: settingsViewController)
    navigationController.popToRootViewController(animated: false)
    navigationController.viewControllers = [drawerController]

    navigationController.isNavigationBarHidden = true

    handlePendingBitcoinURL()
  }

  func continueSetupFlow() {
    let properties = launchStateManager.currentProperties()
    let selectedFlow = launchStateManager.selectedSetupFlow
    let pinAndWalletExist = properties.contains([.pinExists, .walletExists])

    if pinAndWalletExist && verificationSatisfied {
      if launchStateManager.needsUpgradedToSegwit() {
        startSegwitUpgrade()
      } else {
        validToStartEnteringApp()
      }
    } else if pinAndWalletExist {
      startDeviceVerificationFlow(userIdentityType: .phone, shouldOrphanRoot: true, selectedSetupFlow: selectedFlow)
    } else {
      startPinCreation(flow: selectedFlow)
    }
  }

  func startNewWalletFlow(flow: SetupFlow) {
    func createWalletAndContinue() {
      let words = WalletManager.createMnemonicWords()
      self.saveSuccessfulWords(words: words, didBackUp: false)
        .done(on: .main) { _ in
          self.analyticsManager.track(event: .createWallet, with: nil)
          self.analyticsManager.track(property: MixpanelProperty(key: .walletVersion, value: WalletFlagsVersion.v2.rawValue))
          self.continueSetupFlow()
        }.cauterize()
    }

    guard !launchStateManager.shouldRequireAuthentication else {
      requireAuthenticationIfNeeded(whenAuthenticated: createWalletAndContinue)
      return
    }
    guard let topVC = navigationController.topViewController,
      !(topVC is BackupRecoveryWordsViewController) else { return }

    createWalletAndContinue()
  }

  private func startPinCreation(flow: SetupFlow?) {
    let viewController = PinCreationViewController.newInstance(setupFlow: flow, delegate: self)
    navigationController.pushViewController(viewController, animated: true)
  }

  func startFirstTimeAfteriCloudRestore() {
    let title = ""
    let description = "It looks like you have restored from a backup. Please enter your 12 recovery words to restore your wallet."
    let okAction = AlertActionConfiguration(title: "RESTORE NOW", style: .default) { self.restoreWalletAfterICloudRestore() }
    let alertViewModel = AlertControllerViewModel(title: title, description: description, actions: [okAction])
    let alert = alertManager.alert(from: alertViewModel)
    navigationController.topViewController()?.present(alert, animated: true)
  }

  func startDeviceVerificationFlow(userIdentityType type: UserIdentityType,
                                   shouldOrphanRoot: Bool,
                                   selectedSetupFlow: SetupFlow?) {
    func startVerificationFlow() {
      let childCoordinator = DeviceVerificationCoordinator(navigationController,
                                                           delegate: self,
                                                           coordinationDelegate: self,
                                                           userIdentityType: type,
                                                           setupFlow: selectedSetupFlow,
                                                           shouldOrphanRoot: shouldOrphanRoot)
      startChildCoordinator(childCoordinator: childCoordinator)
    }

    guard !launchStateManager.shouldRequireAuthentication else {
      requireAuthenticationIfNeeded(whenAuthenticated: startVerificationFlow)
      return
    }
    guard let topVC = navigationController.topViewController,
      !(topVC is DeviceVerificationViewController) else { return }

    startVerificationFlow()
  }

  /// This calls store(recoveryWords:) which only holds them in memory
  /// until a PIN is entered, then saves both in the keychain at the same time.
  func saveSuccessfulWords(words: [String], didBackUp: Bool) -> Promise<Void> {
    trackIfUserHasWordsBackedUp()
    return persistenceManager.keychainManager.store(recoveryWords: words, isBackedUp: didBackUp)
      .get { _ in self.setWalletManagerWithPersistedWords() }
  }

  func checkForWordsBackedUp() {
    let backupWordsReminderShown = persistenceManager.brokers.activity.backupWordsReminderShown
    guard !wordsBackedUp && !backupWordsReminderShown else { return }
    let title = "Remember to backup your wallet to ensure your Bitcoin is secure in case your phone" +
    " is ever lost or stolen. Tap here to backup now."
    alertManager.showBanner(with: title, duration: nil, alertKind: .error) { [weak self] in
      self?.analyticsManager.track(event: .backupWordsButtonPressed, with: nil)
      self?.showWordRecoveryFlow()
    }
    persistenceManager.brokers.activity.backupWordsReminderShown = true
  }

  func registerWalletWithServerIfNeeded(completion: @escaping CKCompletion) {
    if launchStateManager.shouldRegisterWallet() {
      registerWallet(completion: completion)
    } else {
      completion()
    }
  }

  /// Show the recovery word backup flow.
  ///
  /// - Parameter words: If no parameter is passed in, the default behavior will search the keychain for stored words. Ensure 12 words are passed in.
  func showWordRecoveryFlow(with words: [String] = []) {
    guard let wmgr = walletManager else {
      log.error("WalletManager is nil")
      return
    }

    let usableWords = words.isEmpty ? wmgr.mnemonicWords() : words

    guard usableWords.count == 12 else {
      log.error("Failed to receive 12 words")
      return
    }

    let recoveryWordsIntroVC = RecoveryWordsIntroViewController.newInstance(words: usableWords, delegate: self)
    let navVC = CNNavigationController(rootViewController: recoveryWordsIntroVC)
    navigationController.present(navVC, animated: true, completion: nil)
  }

  private func setupDrawerViewController(centerViewController: UIViewController, leftViewController: UIViewController) -> MMDrawerController {
    let drawerWidth: CGFloat = 118.0
    let drawerController = MMDrawerController(center: centerViewController,
                                              leftDrawerViewController: leftViewController)
    drawerController?.setMaximumLeftDrawerWidth(drawerWidth, animated: false, completion: nil)
    drawerController?.closeDrawerGestureModeMask = [.tapCenterView, .tapNavigationBar, .panningCenterView]
    drawerController?.openDrawerGestureModeMask = [.bezelPanningCenterView]
    drawerController?.shouldStretchDrawer = false
    drawerController?.showsShadow = false
    return drawerController!
  }

  func nextReceiveAddressForRequestPay() -> String? {
    guard let wmgr = walletManager else { return nil }

    var nextAddress: String?
    let bgContext = persistenceManager.createBackgroundContext()
    bgContext.performAndWait {
      nextAddress = wmgr.createAddressDataSource().nextAvailableReceiveAddress(forServerPool: false,
                                                                               indicesToSkip: [],
                                                                               in: bgContext)?.address
    }
    return nextAddress
  }

  func createRequestPayViewController(converter: CurrencyConverter) -> RequestPayViewController? {
    guard let address = nextReceiveAddressForRequestPay() else { return nil }

    let amountVM = CurrencySwappableEditAmountViewModel(exchangeRates: self.currencyController.exchangeRates,
                                                        primaryAmount: .zero,
                                                        walletTransactionType: persistenceManager.brokers.preferences.selectedWalletTransactionType,
                                                        currencyPair: self.currencyController.currencyPair)
    let vm = RequestPayViewModel(receiveAddress: address, amountViewModel: amountVM)
    return RequestPayViewController.newInstance(delegate: self, viewModel: vm, alertManager: self.alertManager)
  }

  private func makeTransactionHistory(type: WalletTransactionType, mock: Bool = false) -> TransactionHistoryViewController {
    let dataSource: TransactionHistoryDataSourceType
    if mock {
      switch type {
      case .onChain:    dataSource = MockTransactionHistoryOnChainDataSource()
      case .lightning:  dataSource = MockTransactionHistoryLightningDataSource()
      }
    } else {
      let context = persistenceManager.viewContext
      switch type {
      case .onChain:    dataSource = TransactionHistoryOnChainDataSource(context: context)
      case .lightning:  dataSource = TransactionHistoryLightningDataSource(context: context)
      }
    }

    return TransactionHistoryViewController.newInstance(withDelegate: self, walletTxType: type, dataSource: dataSource)
  }

  private func makeOverviewController() -> WalletOverviewViewController {
    let shouldLoadMock = self.uiTestArguments.contains(.loadMockTransactionHistory)
    let onChainHistory = makeTransactionHistory(type: .onChain, mock: shouldLoadMock)
    let lightningHistory = makeTransactionHistory(type: .lightning, mock: shouldLoadMock)
    let overviewViewController = WalletOverviewViewController.newInstance(with: self,
                                                                          baseViewControllers: [lightningHistory, onChainHistory],
                                                                          balanceProvider: self,
                                                                          balanceDelegate: self)
    return overviewViewController
  }

}
