//
//  MemoEntryViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 11/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import UIKit

class MemoEntryViewControllerTests: XCTestCase {

  var sut: MemoEntryViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    mockCoordinator = MockCoordinator()
    sut = MemoEntryViewController.makeFromStoryboard()
    sut.delegate = mockCoordinator
    _ = sut.view
  }

  override func tearDown() {
    sut = nil
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.backgroundOverlayView, "backgroundOverlayView should be connected")
    XCTAssertNotNil(self.sut.dismissTapGestureRecognizer, "dismissTapGestureRecognizer should not be connected")
    XCTAssertNotNil(self.sut.backgroundContentImageView, "backgroundContentImageView should be connected")
    XCTAssertNotNil(self.sut.textEntryContainerView, "textEntryContainerView should be connected")
    XCTAssertNotNil(self.sut.textView, "textView should be connected")
    XCTAssertNotNil(self.sut.textEntryContainerViewBottomConstraint, "textEntryContainerViewBottomConstraint should be connected")
    XCTAssertNotNil(self.sut.currentCountLabel, "currentCountLabel should be connected")
    XCTAssertNotNil(self.sut.currentCountSeparatorLabel, "currentCountSeparatorLabel should be connected")
    XCTAssertNotNil(self.sut.currentCountMaxLabel, "currentCountMaxLabel should be connected")
    XCTAssertNotNil(self.sut.countLabels, "countLabels should be connected")
  }

  // MARK: actions
  func testDismissActionCallsCompletionHandler() {
    var returnedMemo = ""
    let expectedMemo = "this should be the resulting memo"
    sut.memo = expectedMemo
    sut.viewDidLoad()
    sut.completion = { memo in returnedMemo = memo }
    sut.dismiss(sut.dismissTapGestureRecognizer)
    XCTAssertEqual(returnedMemo, expectedMemo)
  }

  // MARK: initial state
  func testSettingMemoVariableShowsInTextView() {
    let expectedText = "i am the memo"
    sut.memo = expectedText
    sut.viewDidLoad()
    XCTAssertEqual(sut.textView.text, expectedText)
  }

  func testBackgroundImageGetsSetInViewDidLoad() {
    XCTAssertNil(sut.backgroundContentImageView.image, "image should initially be nil")

    let image = UIImage(named: "fakeQRCode")
    sut.backgroundImage = image

    sut.viewDidLoad()

    XCTAssertNotNil(sut.backgroundContentImageView.image)
  }

  // MARK: private coordinator mock class
  class MockCoordinator: MemoEntryViewControllerDelegate {
    var didTapDismiss = false
    func viewControllerDidDismiss(_ viewController: UIViewController) {
      didTapDismiss = true
    }
  }
}
