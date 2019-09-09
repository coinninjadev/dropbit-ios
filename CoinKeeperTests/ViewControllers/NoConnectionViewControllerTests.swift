//
//  NoConnectionViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class NoConnectionViewControllerTests: XCTestCase {

  var sut: NoConnectionViewController!
  var coordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    sut = NoConnectionViewController.makeFromStoryboard()
    coordinator = MockCoordinator()
    sut.delegate = coordinator
    _ = sut.view
  }

  override func tearDown() {
    coordinator = nil
    sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.retryButton, "retryButton should be connected")
    XCTAssertNotNil(sut.blurViewStackImageView, "blurViewStackImageView should be connected")
    XCTAssertNotNil(sut.noConnectionLabel, "noConnectionLabel should be connected")
    XCTAssertNotNil(sut.activitySpinner, "activitySpinner should be connected")
  }

  func testInitialState() {
    XCTAssertTrue(sut.activitySpinner.isAnimating)
    XCTAssertTrue(sut.activitySpinner.isHidden)
  }

  // MARK: actions
  func testButtonsContainActions() {
    let retryActions = sut.retryButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(NoConnectionViewController.retryConnection(_:)).description
    XCTAssertTrue(retryActions.contains(expected))
  }

  // MARK: actions produce results
  func testRetryButtonTellsDelegateToRetry() {
    sut.retryButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(coordinator.didRequestRetry, "coordinator should be told to retry")
  }

  // MARK: private
  class MockCoordinator: NoConnectionViewControllerDelegate {
    var didRequestRetry = false
    func viewControllerDidRequestRetry(_ viewController: UIKit.UIViewController, completion: @escaping CKCompletion) {
      didRequestRetry = true
    }
  }

}
