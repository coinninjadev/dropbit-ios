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
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    let viewModel = SuccessFailViewModel(mode: .pending)
    self.mockCoordinator = MockCoordinator()
    self.sut = SuccessFailViewController.newInstance(viewModel: viewModel, delegate: mockCoordinator)
    _ = self.sut.view
  }

  override func tearDown() {
    self.mockCoordinator = nil
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
    self.sut.closeButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.wasAskedToClose, "closeButtonTapped should tell delegate to close")
  }

  func testActionButtonTellsDelegateUponSuccess() {
    self.sut.setMode(.success)
    self.sut.actionButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.wasToldAboutSuccess, "success case should tell delegate")
  }

  func testActionButtonCallsRetryHandlerUponFailure() {
    let expectation = XCTestExpectation(description: "testRetryHandleFailure")
    self.sut.setMode(.failure)
    self.sut.action = {
      XCTAssertEqual(self.sut.viewModel.mode, .pending, "mode should change to pending upon failure")
      expectation.fulfill()
    }

    self.sut.actionButton.sendActions(for: .touchUpInside)
    wait(for: [expectation], timeout: 10.0)
  }

  // MARK: mock coordinator
  class MockCoordinator: SuccessFailViewControllerDelegate {
    func viewControllerDidSelectCloseWithToggle(_ viewController: UIViewController) { }
    func viewControllerDidRetry(_ viewController: SuccessFailViewController) {}

    var wasToldAboutSuccess = false
    func viewController(_ viewController: SuccessFailViewController, success: Bool, completion: CKCompletion?) {
      wasToldAboutSuccess = true
    }

    func viewControllerDidRetryPayment() {}

    var wasAskedToClose = false
    func viewControllerDidSelectClose(_ viewController: UIViewController) {
      wasAskedToClose = true
    }

    func viewControllerDidSelectClose(_ viewController: UIViewController, completion: CKCompletion? ) {
      wasAskedToClose = true
    }

    func openURL(_ url: URL, completionHandler completion: CKCompletion?) { }
    func openURLExternally(_ url: URL, completionHandler completion: ((Bool) -> Void)?) { }
  }
}
