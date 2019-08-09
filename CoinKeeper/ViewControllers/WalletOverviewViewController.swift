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

protocol WalletOverviewViewControllerDelegate: BalanceContainerDelegate & BadgeUpdateDelegate {
  var badgeManager: BadgeManagerType { get }
  var currencyController: CurrencyController { get }

  func viewControllerDidTapScan(_ viewController: UIViewController, converter: CurrencyConverter)
  func viewControllerDidTapReceivePayment(_ viewController: UIViewController, converter: CurrencyConverter)
  func viewControllerDidTapSendPayment(_ viewController: UIViewController, converter: CurrencyConverter, walletType: WalletType)
  func viewControllerShouldAdjustForBottomSafeArea(_ viewController: UIViewController) -> Bool
  func viewControllerDidTapWalletTooltip()
  func isSyncCurrentlyRunning() -> Bool
  func viewControllerDidRequestPrimaryCurrencySwap()
}

class WalletOverviewViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var balanceContainer: BalanceContainer!
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
  weak var balanceDelegate: BalanceContainerDelegate?
  var balanceNotificationToken: NotificationToken?
  var pageViewController: UIPageViewController?

  enum ViewControllerIndex: Int {
    case bitcoinWalletTransactionHistory = 0
    case lightningWalletTransactionHistory = 1
  }

  private var currentWallet: ViewControllerIndex = .bitcoinWalletTransactionHistory

  var startSyncNotificationToken: NotificationToken?
  var finishSyncNotificationToken: NotificationToken?

  var coordinationDelegate: WalletOverviewViewControllerDelegate? {
    return generalCoordinationDelegate as? WalletOverviewViewControllerDelegate
  }

  var baseViewControllers: [BaseViewController] = [] {
    willSet {
      for (index, data) in newValue.enumerated() {
        data.view.tag = index
      }
    }
  }

  @IBAction func tooltipButtonWasTouched() {
    coordinationDelegate?.viewControllerDidTapWalletTooltip()
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    guard let transactionHistoryViewController = baseViewControllers[safe: 1] as? TransactionHistoryViewController else { return [] }
    return [
      (self.view, .walletOverview(.page)),
      (self.balanceContainer, .walletOverview(.balanceView)),
      (self.balanceContainer.leftButton, .walletOverview(.menu)),
      (transactionHistoryViewController.view, .walletOverview(.transactionHistory)),
      (sendReceiveActionView.receiveButton, .walletOverview(.receiveButton)),
      (sendReceiveActionView.sendButton, .walletOverview(.sendButton)),
      (transactionHistoryViewController.transactionHistoryNoBalanceView.learnAboutBitcoinButton, .walletOverview(.tutorialButton))
    ]
  }

  static func newInstance(with delegate: WalletOverviewViewControllerDelegate,
                          baseViewControllers: [BaseViewController],
                          balanceProvider: ConvertibleBalanceProvider,
                          balanceDelegate: BalanceContainerDelegate) -> WalletOverviewViewController {
    let controller = WalletOverviewViewController.makeFromStoryboard()
    controller.generalCoordinationDelegate = delegate
    controller.baseViewControllers = baseViewControllers
    controller.balanceProvider = balanceProvider
    controller.balanceDelegate = balanceDelegate
    return controller
  }

  private var showTransactionHistoryToken: NotificationToken?
  private var dismissTransactionHistoryToken: NotificationToken?

  override func viewDidLoad() {
    super.viewDidLoad()

    if let pageViewController = children.first as? UIPageViewController {
      self.pageViewController = pageViewController
      pageViewController.view.layer.masksToBounds = false
    }

    self.showTransactionHistoryToken = CKNotificationCenter
      .subscribe(key: .willShowTransactionHistoryDetails, object: nil, queue: .main) { _ in
    }

    self.dismissTransactionHistoryToken = CKNotificationCenter
      .subscribe(key: .didDismissTransactionHistoryDetails, object: nil, queue: .main) { _ in
    }

    balanceContainer.delegate = balanceDelegate
    pageViewController?.dataSource = self
    pageViewController?.delegate = self
    walletToggleView.delegate = self
    walletBalanceView.delegate = self

    sendReceiveActionView.tintView(with: .bitcoinOrange)

    (coordinationDelegate?.badgeManager).map(subscribeToBadgeNotifications)

    let bottomOffsetIfNeeded: CGFloat = 20
    if let delegate = coordinationDelegate, delegate.viewControllerShouldAdjustForBottomSafeArea(self) {
      sendReceiveActionViewBottomConstraint.constant = bottomOffsetIfNeeded
    }

    subscribeToRateAndBalanceUpdates()
    subscribeToSyncNotifications()
    updateRatesAndBalances()

    self.baseViewControllers.forEach { ($0 as? TransactionHistoryViewController)?.summaryCollectionView.historyDelegate = self }

    pageViewController?.view.layer.cornerRadius = 30.0
    pageViewController?.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    pageViewController?.view.clipsToBounds = true

    if baseViewControllers.count >= 2 {
      pageViewController?.setViewControllers([baseViewControllers[1]], direction: .forward, animated: true, completion: nil)
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.baseViewControllers.compactMap { $0 as? RequestPayViewController}.first?.closeButton?.isHidden = true
  }

  func preferredCurrency() -> CurrencyCode {
    guard let selected = coordinationDelegate?.currencyController.selectedCurrency else { return .USD }
    switch selected {
    case .BTC:
      return .BTC
    case .fiat:
      return .USD
    }
  }

}

extension WalletOverviewViewController: BadgeDisplayable {

  func didReceiveBadgeUpdate(badgeInfo: BadgeInfo) {
    self.balanceContainer.leftButton.updateBadge(with: badgeInfo)
  }

}

extension WalletOverviewViewController: BalanceDisplayable {
  var walletBalanceView: WalletBalanceView { return currentWalletBalanceView }
  var balanceLeftButtonType: BalanceContainerLeftButtonType { return .menu }
  var primaryBalanceCurrency: CurrencyCode {
    guard let selectedCurrency = coordinationDelegate?.selectedCurrency() else { return .BTC }
    switch selectedCurrency {
    case .BTC: return .BTC
    case .fiat: return .USD
    }
  }

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    rateManager.exchangeRates = exchangeRateManager.exchangeRates
    coordinationDelegate?.currencyController.exchangeRates = exchangeRateManager.exchangeRates
    baseViewControllers.compactMap { $0 as? ExchangeRateUpdateable }.forEach { $0.didUpdateExchangeRateManager(exchangeRateManager) }
  }

}

extension WalletOverviewViewController: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                          previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    if let viewContorller = pageViewController.viewControllers?.first as? BaseViewController, completed {
      switch ViewControllerIndex(rawValue: baseViewControllers.reversed().firstIndex(of: viewContorller) ?? 0) {
      case .bitcoinWalletTransactionHistory?:
        walletToggleView.selectBitcoinButton()
        currentWallet = .bitcoinWalletTransactionHistory
        sendReceiveActionView.tintView(with: .bitcoinOrange)
      case .lightningWalletTransactionHistory?:
        walletToggleView.selectLightningButton()
        currentWallet = .lightningWalletTransactionHistory
        sendReceiveActionView.tintView(with: .lightningBlue)
      default:
        walletToggleView.selectBitcoinButton()
      }
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
    sendReceiveActionView.tintView(with: .bitcoinOrange)
    pageViewController?.setViewControllers([baseViewControllers[1]], direction: .reverse, animated: true, completion: nil)
  }

  func lightningWalletButtonWasTouched() {
    sendReceiveActionView.tintView(with: .lightningBlue)
    pageViewController?.setViewControllers([baseViewControllers[0]], direction: .forward, animated: true, completion: nil)
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
    guard let coordinator = coordinationDelegate else { return }
    coordinator.viewControllerDidTapReceivePayment(self, converter: coordinator.currencyController.currencyConverter)
  }

  func actionViewDidSelectScan(_ view: UIView) {
    guard let coordinator = coordinationDelegate else { return }
    coordinator.viewControllerDidTapScan(self, converter: coordinator.currencyController.currencyConverter)
  }

  func actionViewDidSelectSend(_ view: UIView) {
    guard let coordinator = coordinationDelegate else { return }
    let walletType: WalletType = currentWallet == .bitcoinWalletTransactionHistory ? .onChain : .lightning
    coordinator.viewControllerDidTapSendPayment(self, converter: coordinator.currencyController.currencyConverter, walletType: walletType )
  }
}

extension WalletOverviewViewController: SyncSubscribeable {

  func handleStartSync() {
    walletBalanceView.primarySecondaryBalanceContainer.isSyncing = true
  }

  func handleFinishSync() {
    walletBalanceView.primarySecondaryBalanceContainer.isSyncing = false
  }

}

extension WalletOverviewViewController: WalletBalanceViewDelegate {
  func swapPrimaryCurrency() {
    guard let delegate = coordinationDelegate else { return }
    delegate.viewControllerDidRequestPrimaryCurrencySwap()
    updateSelectedCurrency(to: delegate.selectedCurrency())
  }

  func isSyncCurrentlyRunning() -> Bool {
    return coordinationDelegate?.isSyncCurrentlyRunning() ?? false
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
        walletBalanceView.reloadWalletButtonWasTouched()
        return walletBalanceView.reloadWalletButton
      } else if walletBalanceView.primarySecondaryBalanceContainer.frame.contains(balanceViewTranslatedPoint) {
        walletBalanceView.balanceContainerWasTouched()
        return walletBalanceView.primarySecondaryBalanceContainer
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
    guard !balanceContainer.primarySecondaryBalanceContainer.isHidden
      && navigationController?.topViewController() is MMDrawerController else { return }

    balanceContainer.toggleChartAndBalance()
    sendReceiveActionView.isHidden = false
  }

  func collectionViewDidCoverWalletBalance() {
    guard balanceContainer.primarySecondaryBalanceContainer.isHidden else { return }

    balanceContainer.toggleChartAndBalance()
    sendReceiveActionView.isHidden = true
  }
}
