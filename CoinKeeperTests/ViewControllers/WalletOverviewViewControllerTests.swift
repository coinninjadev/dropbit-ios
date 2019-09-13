//
//  WalletOverviewViewControllerTests.swift
//  DropBitTests
//
//  Created by Mitchell Malleo on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
import CoreData
import UIKit
@testable import DropBit
import XCTest

class WalletOverviewViewControllerTests: XCTestCase {
  var sut: WalletOverviewViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    mockCoordinator = MockCoordinator()
    sut = WalletOverviewViewController.newInstance(with: mockCoordinator,
                                                   baseViewControllers: [],
                                                   balanceProvider: mockCoordinator,
                                                   balanceDelegate: mockCoordinator)
    _ = sut.view
  }

  override func tearDown() {
    mockCoordinator = nil
    sut = nil
    super.tearDown()
  }

  // MARK: outlets are connected
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.balanceContainer, "balanceContainer should be connected")
    XCTAssertNotNil(sut.walletToggleView, "walletToggleView should be connected")
    XCTAssertNotNil(sut.sendReceiveActionView, "sendReceiveActionView should be connected")
    XCTAssertNotNil(sut.tooltipButton, "tooltipButton should be connected")
  }

  class MockCoordinator: WalletOverviewViewControllerDelegate, ConvertibleBalanceProvider, BalanceContainerDelegate {
    let badgeManager: BadgeManagerType
    let currencyController: CurrencyController
    let balanceUpdateManager: BalanceUpdateManager

    init() {
      badgeManager = BadgeManager(persistenceManager: MockPersistenceManager())
      currencyController = CurrencyController(fiatCurrency: .USD)
      balanceUpdateManager = BalanceUpdateManager()
    }

    func viewControllerDidTapScan(_ viewController: UIViewController, converter: CurrencyConverter) { }
    func setSelectedWalletTransactionType(_ viewController: UIViewController, to selectedType: WalletTransactionType) { }
    func selectedWalletTransactionType() -> WalletTransactionType {
      return .onChain
    }
    func viewControllerDidTapReceivePayment(_ viewController: UIViewController, converter: CurrencyConverter) { }
    func viewControllerDidTapSendPayment(_ viewController: UIViewController,
                                         converter: CurrencyConverter,
                                         walletTransactionType: WalletTransactionType) { }
    func viewControllerShouldAdjustForBottomSafeArea(_ viewController: UIViewController) -> Bool {
      return true
    }
    func viewControllerDidSelectTransfer(_ viewController: UIViewController) { }
    func viewControllerDidTapWalletTooltip() { }
    func isSyncCurrentlyRunning() -> Bool {
      return false
    }
    func viewControllerDidRequestPrimaryCurrencySwap() { }

    func viewControllerDidRequestBadgeUpdate(_ viewController: UIViewController) { }

    func latestExchangeRates(responseHandler: ExchangeRatesRequest) { }

    func latestFees() -> Promise<Fees> {
      return Promise { _ in }
    }

    func balanceNetPending() -> WalletBalances {
      return WalletBalances(onChain: .zero, lightning: .zero)
    }

    func spendableBalanceNetPending() -> WalletBalances {
      return WalletBalances(onChain: .zero, lightning: .zero)
    }

    func setContextNotificationTokens(willSaveToken: NotificationToken, didSaveToken: NotificationToken) { }
    func handleWillSaveContext(_ context: NSManagedObjectContext) { }
    func handleDidSaveContext(_ context: NSManagedObjectContext) { }

    func containerDidTapLeftButton(in viewController: UIViewController) { }
    func containerDidTapDropBitMe(in viewController: UIViewController) { }
    func didTapRightBalanceView(in viewController: UIViewController) { }
    func didTapChartsButton() { }
    func selectedCurrency() -> SelectedCurrency {
      return .fiat
    }
    func dropBitMeAvatar() -> Promise<UIImage> {
      return Promise { _ in }
    }
  }

}
