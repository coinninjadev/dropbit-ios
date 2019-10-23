//
//  WalletOverviewViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import MMDrawerController

protocol WalletOverviewViewControllerDelegate: WalletOverviewTopBarDelegate & BadgeUpdateDelegate & AnalyticsManagerAccessType {
  var badgeManager: BadgeManagerType { get }
  var currencyController: CurrencyController { get }

  func viewControllerDidTapScan(_ viewController: UIViewController, converter: CurrencyConverter)
  func setSelectedWalletTransactionType(_ viewController: UIViewController, to selectedType: WalletTransactionType)
  func selectedWalletTransactionType() -> WalletTransactionType
  func viewControllerDidTapReceivePayment(_ viewController: UIViewController,
                                          converter: CurrencyConverter, walletTransactionType: WalletTransactionType)
  func viewControllerDidTapSendPayment(_ viewController: UIViewController, converter: CurrencyConverter,
                                       walletTransactionType: WalletTransactionType)
  func viewControllerShouldAdjustForBottomSafeArea(_ viewController: UIViewController) -> Bool
  func viewControllerDidSelectTransfer(_ viewController: UIViewController)
  func viewControllerDidTapWalletTooltip()
  func isSyncCurrentlyRunning() -> Bool
  func viewControllerDidRequestPrimaryCurrencySwap()
}

class WalletOverviewViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var topBar: WalletOverviewTopBar!
  @IBOutlet var walletToggleView: WalletToggleView!
  @IBOutlet var tooltipButton: UIButton!
  @IBOutlet var sendReceiveActionViewBottomConstraint: NSLayoutConstraint!
  @IBOutlet var currentWalletBalanceView: WalletBalanceView!
  @IBOutlet var sendReceiveActionView: SendReceiveActionView! {
    didSet {
      sendReceiveActionView.actionDelegate = self
    }
  }

  let rateManager = ExchangeRateManager()
  var badgeNotificationToken: NotificationToken?
  weak var balanceProvider: ConvertibleBalanceProvider?
  weak var balanceDelegate: DualBalanceViewDelegate?
  weak var topBarDelegate: WalletOverviewTopBarDelegate?
  var balanceNotificationToken: NotificationToken?
  var pageViewController: UIPageViewController?

  private var currentWallet: WalletTransactionType = .onChain {
    willSet {
      guard currentWallet != newValue else { return }
      delegate.setSelectedWalletTransactionType(self, to: newValue)
    }
    didSet {
      updateViewWithBalance()
    }
  }

  var startSyncNotificationToken: NotificationToken?
  var finishSyncNotificationToken: NotificationToken?

  private(set) weak var delegate: WalletOverviewViewControllerDelegate!

  var baseViewControllers: [BaseViewController] = [] {
    willSet {
      for (index, data) in newValue.enumerated() {
        data.view.tag = index
      }
    }
  }

  @IBAction func tooltipButtonWasTouched() {
    delegate.viewControllerDidTapWalletTooltip()
    delegate.viewControllerShouldTrackEvent(event: .walletToggleTooltipPressed)
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    guard let transactionHistoryViewController = baseViewControllers[safe: 1] as? TransactionHistoryViewController else { return [] }
    return [
      (self.view, .walletOverview(.page)),
      (self.topBar, .walletOverview(.balanceView)),
      (self.topBar.leftButton, .walletOverview(.menu)),
      (transactionHistoryViewController.view, .walletOverview(.transactionHistory)),
      (sendReceiveActionView.receiveButton, .walletOverview(.receiveButton)),
      (sendReceiveActionView.sendButton, .walletOverview(.sendButton)),
      (transactionHistoryViewController.transactionHistoryNoBalanceView.learnAboutBitcoinButton, .walletOverview(.tutorialButton))
    ]
  }

  //TODO: ensure balanceProvider never returns negative value for either balance
  static func newInstance(with delegate: WalletOverviewViewControllerDelegate,
                          baseViewControllers: [BaseViewController],
                          balanceProvider: ConvertibleBalanceProvider,
                          balanceDelegate: WalletOverviewTopBarDelegate) -> WalletOverviewViewController {
    let controller = WalletOverviewViewController.makeFromStoryboard()
    controller.delegate = delegate
    controller.baseViewControllers = baseViewControllers
    controller.balanceProvider = balanceProvider
    controller.balanceDelegate = balanceDelegate
    return controller
  }

  private var reloadTransactionsToken: NotificationToken?

  override func viewDidLoad() {
    super.viewDidLoad()

    if let pageViewController = children.first as? UIPageViewController {
      self.pageViewController = pageViewController
      pageViewController.view.layer.masksToBounds = false
    }

    self.reloadTransactionsToken = CKNotificationCenter
      .subscribe(key: .didUpdateLocalTransactionRecords, object: nil, queue: .main) { _ in
        self.baseViewControllers.forEach { ($0 as? TransactionHistoryViewController)?.summaryCollectionView.reloadData() }
    }

    topBar.delegate = topBarDelegate
    pageViewController?.dataSource = self
    pageViewController?.delegate = self
    walletToggleView.delegate = self
    walletBalanceView.delegate = self

    sendReceiveActionView.tintView(with: .bitcoinOrange)

    self.subscribeToBadgeNotifications(with: delegate.badgeManager)

    let bottomOffsetIfNeeded: CGFloat = 20
    if delegate.viewControllerShouldAdjustForBottomSafeArea(self) {
      sendReceiveActionViewBottomConstraint.constant = bottomOffsetIfNeeded
    }

    subscribeToRateAndBalanceUpdates()
    subscribeToSyncNotifications()
    updateRatesAndBalances()

    self.baseViewControllers.forEach { ($0 as? TransactionHistoryViewController)?.summaryCollectionView.historyDelegate = self }

    pageViewController?.view.layer.cornerRadius = 30.0
    pageViewController?.view.layer.maskedCorners = .top
    pageViewController?.view.clipsToBounds = true

    if baseViewControllers.count >= 2 {
      switch delegate.selectedWalletTransactionType() {
      case .lightning:
        setupUI(for: .lightningWallet)
      case .onChain:
        setupUI(for: .bitcoinWallet)
      }
    }
  }

  override func lock() {
    if delegate.selectedWalletTransactionType() == .lightning {
      sendReceiveActionView.isHidden = true
    }

    walletBalanceView.reloadWalletButton.isHidden = true
  }

  override func makeUnavailable() {
    lock()
  }

  override func unlock() {
    sendReceiveActionView.isHidden = false
    walletBalanceView.reloadWalletButton.isHidden = false
  }

  private func setupStyleForOnChainWallet() {
    guard baseViewControllers.count >= 2 else { return }
    walletToggleView.selectBitcoinButton()
    currentWallet = .onChain
    sendReceiveActionView.tintView(with: .bitcoinOrange)
  }

  private func setupStyleForLightningWallet() {
    guard baseViewControllers.count >= 1 else { return }
    walletToggleView.selectLightningButton()
    currentWallet = .lightning
    sendReceiveActionView.tintView(with: .lightningBlue)
  }

  private func setupUI(for wallet: ViewControllerIndex?) {
    switch wallet {
    case .bitcoinWallet?:
      setupStyleForOnChainWallet()
      sendReceiveActionView.isHidden = false
      pageViewController?.setViewControllers([baseViewControllers[1]], direction: .reverse, animated: true, completion: nil)
    case .lightningWallet?:
      setupStyleForLightningWallet()
      sendReceiveActionView.isHidden = currentLockStatus == .locked
      pageViewController?.setViewControllers([baseViewControllers[0]], direction: .forward, animated: true, completion: nil)
    default:
      walletToggleView.selectBitcoinButton()
    }

    refreshLockStatus()
  }
}

extension WalletOverviewViewController: BadgeDisplayable {

  func didReceiveBadgeUpdate(badgeInfo: BadgeInfo) {
    self.topBar.leftButton.updateBadge(with: badgeInfo)
  }

}

extension WalletOverviewViewController: BalanceDisplayable {

  var exchangeRates: ExchangeRates {
    return rateManager.exchangeRates
  }

  var fromAmount: NSDecimalNumber {
    guard let provider = balanceProvider else { return .zero }
    let balances = provider.spendableBalancesNetPending()
    switch walletTransactionType {
    case .onChain:    return balances.onChain
    case .lightning:  return balances.lightning
    }
  }

  var currencyPair: CurrencyPair {
    return delegate.currencyController.currencyPair
  }

  var walletBalanceView: WalletBalanceView { return currentWalletBalanceView }
  var primaryBalanceCurrency: CurrencyCode {
    let selectedCurrency = delegate.selectedCurrency()
    switch selectedCurrency {
    case .BTC: return .BTC
    case .fiat: return .USD
    }
  }

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    rateManager.exchangeRates = exchangeRateManager.exchangeRates
    delegate.currencyController.exchangeRates = exchangeRateManager.exchangeRates
    baseViewControllers.compactMap { $0 as? ExchangeRateUpdatable }.forEach { $0.didUpdateExchangeRateManager(exchangeRateManager) }
  }

  var walletTransactionType: WalletTransactionType {
    return delegate.selectedWalletTransactionType()
  }
}

enum ViewControllerIndex: Int {
  case bitcoinWallet = 0
  case lightningWallet = 1
}

extension WalletOverviewViewController: UIPageViewControllerDelegate {

  func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
    if currentLockStatus == .locked {
      sendReceiveActionView.isHidden = true
    }
  }

  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                          previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    if let viewController = pageViewController.viewControllers?.first as? BaseViewController {
      let index = ViewControllerIndex(rawValue: baseViewControllers.reversed().firstIndex(of: viewController) ?? 0)
      switch index {
      case .bitcoinWallet:
        delegate.viewControllerShouldTrackEvent(event: .onChainWalletSelected)
      case .lightningWallet:
        delegate.viewControllerShouldTrackEvent(event: .lightningWalletSelected)
      default:
        break
      }

      setupUI(for: index)
    }
  }
}

extension WalletOverviewViewController: UIPageViewControllerDataSource {

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let baseViewController = viewController as? BaseViewController,
      let index = baseViewControllers.firstIndex(of: baseViewController) else { return nil }

    return baseViewControllers[safe: index + 1]
  }

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let baseViewController = viewController as? BaseViewController,
      let index = baseViewControllers.firstIndex(of: baseViewController) else { return nil }

    return baseViewControllers[safe: index - 1]
  }
}

extension WalletOverviewViewController: WalletToggleViewDelegate {

  func bitcoinWalletButtonWasTouched() {
    delegate.viewControllerShouldTrackEvent(event: .onChainWalletSelected)
    setupUI(for: .bitcoinWallet)
  }

  func lightningWalletButtonWasTouched() {
    delegate.viewControllerShouldTrackEvent(event: .lightningWalletSelected)
    setupUI(for: .lightningWallet)
  }
}

extension WalletOverviewViewController: SelectedCurrencyUpdatable {
  func updateSelectedCurrency(to selectedCurrency: SelectedCurrency) {
    updateViewWithBalance()
    baseViewControllers.compactMap { $0 as? SelectedCurrencyUpdatable }.forEach { $0.updateSelectedCurrency(to: selectedCurrency) }
  }
}

extension WalletOverviewViewController: SendReceiveActionViewDelegate {
  func actionViewDidSelectReceive(_ view: UIView) {
    let converter = delegate.currencyController.currencyConverter
    delegate.viewControllerDidTapReceivePayment(self, converter: converter, walletTransactionType: walletTransactionType)
  }

  func actionViewDidSelectScan(_ view: UIView) {
    let converter = delegate.currencyController.currencyConverter
    delegate.viewControllerDidTapScan(self, converter: converter)
  }

  func actionViewDidSelectSend(_ view: UIView) {
    let converter = delegate.currencyController.currencyConverter
    delegate.viewControllerDidTapSendPayment(self, converter: converter,
                                                walletTransactionType: currentWallet)
  }
}

extension WalletOverviewViewController: SyncSubscribeable {

  func handleStartSync() {
    walletBalanceView.balanceView.isSyncing = true
  }

  func handleFinishSync() {
    walletBalanceView.balanceView.isSyncing = false
  }

}

extension WalletOverviewViewController: WalletBalanceViewDelegate {
  func currentLockStatus() -> LockStatus {
    return currentLockStatus
  }

  func transferButtonWasTouched() {
    delegate.viewControllerDidSelectTransfer(self)
  }

  func selectedCurrency() -> SelectedCurrency {
    return delegate.selectedCurrency()
  }

  func swapSelectedCurrency() {
    delegate.viewControllerDidRequestPrimaryCurrencySwap()
    let newSelectedCurrency = delegate.selectedCurrency()
    updateSelectedCurrency(to: newSelectedCurrency)
  }

  func isSyncCurrentlyRunning() -> Bool {
    return delegate.isSyncCurrentlyRunning()
  }

}

extension WalletOverviewViewController: TransactionHistorySummaryCollectionViewDelegate {

  func collectionViewDidProvideHitTestPoint(_ point: CGPoint, in view: UIView) -> UIView? {
    let translatedPoint = view.convert(point, to: self.view)
    if walletToggleView.frame.contains(translatedPoint) {
      let toggleTranslatedPoint = self.view.convert(translatedPoint, to: walletToggleView)
      walletToggleView.bitcoinWalletButton.frame.contains(toggleTranslatedPoint) ?
        walletToggleView.bitcoinWalletWasTouched() : walletToggleView.lightningWalletWasTouched()
      return walletToggleView
    } else if walletBalanceView.frame.contains(translatedPoint) {
      let balanceViewTranslatedPoint = self.view.convert(translatedPoint, to: walletBalanceView)
      if walletBalanceView.reloadWalletButton.frame.contains(balanceViewTranslatedPoint) {
        walletBalanceView.transferButtonWasTouched()
        return walletBalanceView.reloadWalletButton
      } else if walletBalanceView.balanceView.frame.contains(balanceViewTranslatedPoint) {
        walletBalanceView.balanceViewWasTouched()
        return walletBalanceView.balanceView
      } else {
        return walletBalanceView
      }
    } else if tooltipButton.frame.contains(translatedPoint) {
      tooltipButtonWasTouched()
      return tooltipButton
    } else {
      return nil
    }
  }

  func collectionViewDidUncoverWalletBalance() {
    guard !topBar.balanceView.isHidden
      && navigationController?.topViewController() is MMDrawerController else { return }

    topBar.toggleChartAndBalance()
    sendReceiveActionView.isHidden = false
  }

  func collectionViewDidCoverWalletBalance() {
    guard topBar.balanceView.isHidden else { return }

    topBar.toggleChartAndBalance()
    sendReceiveActionView.isHidden = true
  }
}
