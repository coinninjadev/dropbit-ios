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
    sut = TransactionHistoryDetailsViewController.makeFromStoryboard()
    sut.generalCoordinationDelegate = mockCoordinator
    sut.urlOpener = mockCoordinator
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

  func testAddingMemoTellsDelegate() {
    sut.didTapAddMemoButton { (memo) in
      XCTAssertEqual(memo, "temp memo for testing purposes")
    }
  }

  func testTappingQuestionMarkButtonTellsDelegate() {
    let address = "https://foo.com"
    sut.didTapQuestionMarkButton(detailCell: TransactionHistoryDetailBaseCell(), with: URL(string: address)!)
    XCTAssertEqual(mockCoordinator.urlToOpen.absoluteString, address)
  }

  // MARK: private class
  class MockCoordinator: TransactionHistoryDetailsViewControllerDelegate, URLOpener {
    var wasAskedToDismissDetailsController = false
    func viewControllerDidDismissTransactionDetails(_ viewController: UIViewController) {
      wasAskedToDismissDetailsController = true
    }

    func viewControllerShouldSeeTransactionDetails(for viewModel: TransactionHistoryDetailCellViewModel) { }

    func viewController(_ viewController: TransactionHistoryDetailsViewController,
                        didCancelInvitationWithID invitationID: String,
                        at indexPath: IndexPath) { }

    func viewControllerDidTapAddMemo(_ viewController: UIViewController, with completion: @escaping (String) -> Void) {
      completion("temp memo for testing purposes")
    }

    func viewControllerShouldUpdateTransaction(_ viewController: TransactionHistoryDetailsViewController,
                                               transaction: CKMTransaction) -> Promise<Void> {
      return Promise.value(())
    }

    func viewControllerRequestedShareTransactionOnTwitter(_ viewController: UIViewController,
                                                          transaction: CKMTransaction?,
                                                          shouldDismiss: Bool) { }

    var urlToOpen: URL!
    func openURL(_ url: URL, completionHandler completion: CKCompletion?) {
      urlToOpen = url
    }

    func openURLExternally(_ url: URL, completionHandler completion: ((Bool) -> Void)?) { }
  }
}
