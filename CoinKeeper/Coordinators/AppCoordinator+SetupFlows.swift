//
//  AppCoordinator+SetupFlows.swift
//  DropBit
//
//  Created by Ben Winters on 5/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import os.log
import UIKit
import MMDrawerController

extension AppCoordinator {

  var wordsBackedUp: Bool {
    return launchStateManager.walletIsBackedUp()
  }

  var verificationSatisfied: Bool {
    return launchStateManager.deviceIsVerified() || launchStateManager.skippedVerification
  }

  var isFirstTimeOpeningApp: Bool {
    return !persistenceManager.bool(for: .firstTimeOpeningApp)
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

  func continueSetupFlow() {
    let properties = launchStateManager.currentProperties()

    if properties.contains([.pinExists, .walletExists]) && verificationSatisfied {
      validToStartEnteringApp()
    } else if properties.contains(.walletExists) {
      startDeviceVerificationFlow(shouldOrphanRoot: true, selectedSetupFlow: launchStateManager.selectedSetupFlow)
    } else {

    }
  }

  func startNewWalletFlow(animated: Bool = true) {
    func createWalletAndContinue() {
      let words = WalletManager.createMnemonicWords()
      self.saveSuccessfulWords(words: words, didBackUp: false)
      analyticsManager.track(event: .createWallet, with: nil)
      self.continueSetupFlow()
    }

    guard !launchStateManager.shouldRequireAuthentication else {
      requireAuthenticationIfNeeded(whenAuthenticated: createWalletAndContinue)
      return
    }
    guard let topVC = navigationController.topViewController,
      !(topVC is BackupRecoveryWordsViewController) else { return }

    createWalletAndContinue()
  }

  private func startFirstTimeWalletCreationFlow(_ flow: SetupFlow) {
    switch flow {
    case .restoreWallet:
      let viewController = RestoreWalletViewController.makeFromStoryboard()
      assignCoordinationDelegate(to: viewController)
      navigationController.pushViewController(viewController, animated: true)

    case .newWallet, .claimInvite:
      startPinCreation(flow: flow)
    }
  }

  private func startPinCreation(flow: SetupFlow?) {
    let viewController = PinCreationViewController.makeFromStoryboard()
    viewController.setupFlow = flow
    assignCoordinationDelegate(to: viewController)
    navigationController.pushViewController(viewController, animated: true)
  }

  func startFirstTimeAfteriCloudRestore() {
    let title = ""
    let description = "It looks like you have restored from a backup. Please enter your 12 recovery words to restore your wallet."
    let okAction = AlertActionConfiguration(title: "RESTORE NOW", style: .default) { self.restoreWallet() }
    let alertViewModel = AlertControllerViewModel(title: title, description: description, actions: [okAction])
    let alert = alertManager.alert(from: alertViewModel)
    navigationController.topViewController()?.present(alert, animated: true)
  }

  func startDeviceVerificationFlow(shouldOrphanRoot: Bool, selectedSetupFlow: SetupFlow?) {
    func startVerificationFlow() {
      let childCoordinator = DeviceVerificationCoordinator(navigationController, shouldOrphanRoot: shouldOrphanRoot)
      childCoordinator.selectedSetupFlow = selectedSetupFlow
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

  func saveSuccessfulWords(words: [String], didBackUp: Bool) {
    trackIfUserHasWordsBackedUp()
    persistenceManager.backup(recoveryWords: words)

    //This wouldn't be called when we allow them to set up a wallet without backing up their words
    //Important to store boolean as NSNumber for the keychain
    guard persistenceManager.keychainManager.store(anyValue: NSNumber(value: didBackUp), key: .walletWordsBackedUp) else {
      fatalError("Failed to write status to keychain for walletWordsBackedUp")
    }
  }

  func checkForWordsBackedUp() {
    let backupWordsReminderShown = persistenceManager.bool(for: .backupWordsReminderShown)
    guard !wordsBackedUp && !backupWordsReminderShown else { return }
    let title = "Remember to backup your wallet to ensure your Bitcoin is secure in case your phone" +
    " is ever lost or stolen. Tap here to backup now."
    alertManager.showBanner(with: title, duration: nil, alertKind: .error) { [weak self] in
      self?.analyticsManager.track(event: .backupWordsButtonPressed, with: nil)
      self?.showWordRecoveryFlow()
    }
    persistenceManager.set(true, for: .backupWordsReminderShown)
  }

  func registerWalletWithServerIfNeeded(completion: @escaping () -> Void) {
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
    recoveryWordsIntroViewController.recoveryWords = usableWords
    assignCoordinationDelegate(to: recoveryWordsIntroViewController)
    navigationController.present(CNNavigationController(rootViewController: recoveryWordsIntroViewController),
                                 animated: false,
                                 completion: nil)
  }

  func createPinEntryViewControllerForRecoveryWords(_ words: [String]) -> PinEntryViewController {
    let pinEntryViewController = PinEntryViewController.makeFromStoryboard()
    pinEntryViewController.mode = .recoveryWords(completion: { _ in
      let wordsViewController = BackupRecoveryWordsViewController.makeFromStoryboard()
      wordsViewController.recoveryWords = words
      wordsViewController.wordsBackedUp = self.wordsBackedUp
      self.analyticsManager.track(event: .viewWords, with: nil)
      self.assignCoordinationDelegate(to: wordsViewController)
      self.navigationController.present(CNNavigationController(rootViewController: wordsViewController), animated: false, completion: nil)
    })
    assignCoordinationDelegate(to: pinEntryViewController)

    return pinEntryViewController
  }

  private func makeTransactionHistory() -> TransactionHistoryViewController {
    let txHistory = TransactionHistoryViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: txHistory)
    txHistory.context = persistenceManager.mainQueueContext()
    txHistory.balanceProvider = self
    txHistory.balanceDelegate = self
    txHistory.urlOpener = self
    return txHistory
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

}
