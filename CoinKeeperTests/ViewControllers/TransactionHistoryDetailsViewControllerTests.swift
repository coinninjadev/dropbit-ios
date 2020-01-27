//
//  TransactionHistoryDetailsViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 7/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import PromiseKit

class TransactionHistoryDetailsViewControllerTests: XCTestCase {

  var sut: TransactionHistoryDetailsViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    mockCoordinator = MockCoordinator()
    let dataSource = MockTransactionHistoryOnChainDataSource()
    sut = TransactionHistoryDetailsViewController.newInstance(withDelegate: mockCoordinator,
                                                              walletTxType: .onChain,
                                                              selectedIndexPath: IndexPath(item: 0, section: 0),
                                                              dataSource: dataSource)
    _ = sut.view
  }

  override func tearDown() {
    sut = nil
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.collectionView, "collectionView should be connected")
  }

  // MARK: actions
  func testDismissingControllerTellsDelegate() {
    sut.didTapClose(detailCell: TransactionHistoryDetailBaseCell())
    XCTAssertTrue(mockCoordinator.wasAskedToDismissDetailsController)
  }

  func testTappingQuestionMarkButtonTellsDelegate() {
    let toolTip = DetailCellTooltip(rawValue: 1)!
    sut.didTapQuestionMarkButton(detailCell: TransactionHistoryDetailBaseCell(), tooltip: toolTip)
    XCTAssertTrue(mockCoordinator.wasAskedToOpenURL)
  }

  // MARK: private class
  class MockCoordinator: TransactionHistoryDetailsViewControllerDelegate, URLOpener {

    var uiTestIsInProgress: Bool { false }

    let currencyController: CurrencyController = CurrencyController(fiatCurrency: .USD)

    func latestExchangeRates(responseHandler: (ExchangeRates) -> Void) {
      responseHandler(CurrencyConverter.sampleRates)
    }

    func latestExchangeRates() -> Promise<ExchangeRates> { Promise { _ in } }
    func latestFees() -> Promise<Fees> { Promise { _ in } }

    func deviceCountryCode() -> Int? {
      return 1
    }

    var wasAskedToDismissDetailsController = false
    func viewControllerDidDismissTransactionDetails(_ viewController: UIViewController) {
      wasAskedToDismissDetailsController = true
    }

    func viewController(_ viewController: TransactionHistoryDetailsViewController,
                        didCancelInvitationWithID invitationID: String,
                        at indexPath: IndexPath) { }

    func viewControllerDidTapAddMemo(_ viewController: UIViewController,
                                     with completion: @escaping (String) -> Void) { }

    func viewControllerRequestedShareTransactionOnTwitter(_ viewController: UIViewController,
                                                          walletTxType: WalletTransactionType,
                                                          transaction: TransactionDetailCellActionable?,
                                                          shouldDismiss: Bool) { }

    var wasAskedToOpenURL = false
    func openURL(_ url: URL, completionHandler completion: CKCompletion?) {
      wasAskedToOpenURL = true
    }

    func openURLExternally(_ url: URL, completionHandler completion: ((Bool) -> Void)?) { }
    func viewControllerShouldSeeTransactionDetails(for viewModel: TransactionDetailPopoverDisplayable) { }
    func viewControllerSuccessfullyCopiedToClipboard(message: String, viewController: UIViewController) { }
  }
}
