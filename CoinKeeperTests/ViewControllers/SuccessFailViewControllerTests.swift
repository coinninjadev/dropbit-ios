//
//  SuccessFailViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 5/21/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class SuccessFailViewControllerTests: XCTestCase {
  var sut: SuccessFailViewController!

  override func setUp() {
    super.setUp()
    self.sut = SuccessFailViewController.makeFromStoryboard()
    _ = self.sut.view
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.successFailView, "successFailView should be connected")
    XCTAssertNotNil(self.sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(self.sut.titleLabel, "titleLabel should be connected")
    XCTAssertNotNil(self.sut.actionButton, "actionButton should be connected")
  }

  // MARK: buttons contain actions
  func testCloseButtonContainsAction() {
    let actions = self.sut.closeButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let closeSelector = #selector(SuccessFailViewController.closeButtonWasTouched)
    XCTAssertTrue(actions.contains(closeSelector.description), "closeButton should contain action")
  }

  func testActionButtonContainsAction() {
    let actions = self.sut.actionButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let actionSelector = #selector(SuccessFailViewController.actionButtonWasTouched)
    XCTAssertTrue(actions.contains(actionSelector.description), "actionButton should contain action")
  }

  // MARK: actions produce results
  func testCloseButtonTellsDelegateToClose() {
    let mockCoordinator = MockCoordinator()
    self.sut.generalCoordinationDelegate = mockCoordinator

    self.sut.closeButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.wasAskedToClose, "closeButtonTapped should tell delegate to close")
  }

  func testActionButtonTellsDelegateUponSuccess() {
    let mockCoordinator = MockCoordinator()
    self.sut.generalCoordinationDelegate = mockCoordinator
    self.sut.mode = .success

    self.sut.actionButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.wasToldAboutSuccess, "success case should tell delegate")
  }

  func testActionButtonCallsRetryHandlerUponFailure() {
    let mockCoordinator = MockCoordinator()
    self.sut.generalCoordinationDelegate = mockCoordinator
    self.sut.mode = .failure
    var handlerExecuted = false
    self.sut.retryCompletion = { handlerExecuted = true }

    self.sut.actionButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(handlerExecuted, "retryRequestCompletion should execute upon failure")
    XCTAssertEqual(self.sut.mode, .pending, "mode should change to pending upon failure")
  }

  // MARK: mock coordinator
  class MockCoordinator: SuccessFailViewControllerDelegate {
    func viewControllerDidRetry(_ viewController: SuccessFailViewController) {}

    var wasToldAboutSuccess = false
    func viewController(_ viewController: SuccessFailViewController, success: Bool, completion: (() -> Void)?) {
      wasToldAboutSuccess = true
    }

    func viewControllerDidRetryPayment() {}

    var wasAskedToClose = false
    func viewControllerDidSelectClose(_ viewController: UIViewController) {
      wasAskedToClose = true
    }
  }
}
