//
//  TransactionHistoryViewControllerTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 4/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit
import UIKit
@testable import DropBit
import XCTest

class TransactionHistoryViewControllerTests: XCTestCase {
  var sut: TransactionHistoryViewController!
  var stack: InMemoryCoreDataStack!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    stack = InMemoryCoreDataStack()
    self.mockCoordinator = MockCoordinator()
    let dataSource = MockTransactionHistoryOnChainDataSource()
    sut = TransactionHistoryViewController.newInstance(withDelegate: self.mockCoordinator,
                                                       walletTxType: .onChain,
                                                       dataSource: dataSource)
    _ = sut.view
  }

  override func tearDown() {
    mockCoordinator = nil
    sut = nil
    stack = nil
    super.tearDown()
  }

  // MARK: outlets are connected
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.summaryCollectionView, "summaryCollectionView should be connected")
    XCTAssertNotNil(sut.transactionHistoryNoBalanceView, "transactionHistoryNoBalanceView should be connected")
    XCTAssertNotNil(sut.transactionHistoryWithBalanceView, "transactionHistoryWithBalanceView should be connected")
    XCTAssertNotNil(sut.refreshView, "refreshView should be connected")
    XCTAssertNotNil(sut.refreshViewTopConstraint, "refreshViewTopConstraint should be connected")
    XCTAssertNotNil(sut.gradientBlurView, "gradientBlurView should be connected")
  }

  // MARK: no transactions
  func testNoTransactionsShowsNoTransactionsViewAndHidesSummaryCollectionView() {
    sut.summaryCollectionView.reloadData()
    XCTAssertFalse(sut.transactionHistoryNoBalanceView.isHidden, "noTransactionsView should be visible when no transactions are in context")
  }

  class MockCoordinator: TransactionHistoryViewControllerDelegate {

    var didSendTweet = false
    func openTwitterURL(withMessage message: String) {
      didSendTweet = true
    }

    var didRequestLightningLoad = false
    func didRequestLightningLoad(withAmount amount: TransferAmount) {
      didRequestLightningLoad = true
    }

    func viewControllerDidRequestHistoryUpdate(_ viewController: TransactionHistoryViewController) { }
    func viewControllerDidDisplayTransactions(_ viewController: TransactionHistoryViewController) { }
    func viewControllerAttemptedToRefreshTransactions(_ viewController: UIViewController) { }

    func viewControllerDidRequestTutorial(_ viewController: UIViewController) { }
    func viewControllerDidTapGetBitcoin(_ viewController: UIViewController) { }
    func viewControllerDidTapSpendBitcoin(_ viewController: UIViewController) { }

    var currencyController: CurrencyController {
      return CurrencyController(fiatCurrency: .USD)
    }

    func viewControllerSummariesDidReload(_ viewController: TransactionHistoryViewController, indexPathsIfNotAll paths: [IndexPath]?) { }
    func viewControllerWillShowTransactionDetails(_ viewController: UIViewController) { }
    func viewController(_ viewController: TransactionHistoryViewController, didSelectItemAtIndexPath indexPath: IndexPath) { }
    func viewControllerDidDismissTransactionDetails(_ viewController: UIViewController) { }

    func deviceCountryCode() -> Int? {
      return 1
    }

    func viewControllerDidRequestBadgeUpdate(_ viewController: UIViewController) { }

    func openURL(_ url: URL, completionHandler completion: CKCompletion?) { }
    func openURLExternally(_ url: URL, completionHandler completion: ((Bool) -> Void)?) { }

    func emptyViewDidRequestRefill(withAmount amount: TransferAmount) { }

    func latestExchangeRates(responseHandler: ExchangeRatesRequest) { }
    func latestExchangeRates() -> Promise<ExchangeRates> { Promise { _ in } }
    func latestFees() -> Promise<Fees> { Promise { _ in } }

    func viewControllerDidSelectSummaryHeader(_ viewController: UIViewController) { }
    func summaryHeaderType(for viewController: UIViewController) -> SummaryHeaderType? {
      return nil
    }
  }
}
