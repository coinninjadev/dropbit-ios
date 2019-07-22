//
//  WalletOverviewViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol WalletOverviewViewControllerDelegate: BalanceContainerDelegate & BadgeUpdateDelegate {
  var badgeManager: BadgeManagerType { get }
  var currencyController: CurrencyController { get }
}

class WalletOverviewViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var balanceContainer: BalanceContainer!

  let rateManager = ExchangeRateManager()
  var badgeNotificationToken: NotificationToken?
  weak var balanceProvider: ConvertibleBalanceProvider?
  weak var balanceDelegate: BalanceContainerDelegate?
  var balanceNotificationToken: NotificationToken?
  var pageViewController: UIPageViewController?

  enum ViewControllerIndex: Int {
    case transactionHistoryViewController = 0
  }

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

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    guard let transactionHistoryViewController = baseViewControllers[0] as? TransactionHistoryViewController,
      let sendReceiveActionView = transactionHistoryViewController.sendReceiveActionView else { return [] }
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

  override func viewDidLoad() {
    super.viewDidLoad()

    if let pageViewController = children.first as? UIPageViewController {
      self.pageViewController = pageViewController
      pageViewController.view.layer.masksToBounds = false
    }

    balanceContainer.delegate = balanceDelegate

    (coordinationDelegate?.badgeManager).map(subscribeToBadgeNotifications)

    subscribeToRateAndBalanceUpdates()
    updateRatesAndBalances()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    pageViewController?.setViewControllers([baseViewControllers[0]], direction: .forward, animated: true, completion: nil)
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

extension WalletOverviewViewController: SelectedCurrencyUpdatable {
  func updateSelectedCurrency(to selectedCurrency: SelectedCurrency) {
    updateViewWithBalance()
    baseViewControllers.compactMap { $0 as? SelectedCurrencyUpdatable }.forEach { $0.updateSelectedCurrency(to: selectedCurrency) }
  }
}
