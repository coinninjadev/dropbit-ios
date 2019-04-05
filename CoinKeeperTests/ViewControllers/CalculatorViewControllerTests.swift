//
//  CalculatorViewControllerTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 3/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import PromiseKit
import XCTest

class CalculatorViewControllerTests: XCTestCase {

  var sut: CalculatorViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()

    self.sut = CalculatorViewController.makeFromStoryboard()
    _ = self.sut.view

    self.mockCoordinator = MockCoordinator()
    self.sut.generalCoordinationDelegate = mockCoordinator
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.keypadView, "keypadView should be connected")
    XCTAssertNotNil(self.sut.primaryAmountLabel, "primaryAmountLabel should be connected")
    XCTAssertNotNil(self.sut.secondaryAmountLabel, "secondaryAmountLabel should be connected")
    XCTAssertNotNil(self.sut.currencyToggle, "currencyToggle should be connected")
    XCTAssertNotNil(self.sut.balanceContainer, "balanceContainer should be connected")
    XCTAssertNotNil(self.sut.receiveButton, "receiveButton should be connected")
    XCTAssertNotNil(self.sut.scanButton, "scanButton should be connected")
    XCTAssertNotNil(self.sut.sendButton, "sendButton should be connected")
  }

  // MARK: actionable controls contain actions
  func testRequestButtonContainsAction() {
    let actions = self.sut.receiveButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let receiveSelector = #selector(CalculatorViewController.didTapReceive(_:)).description
    XCTAssertTrue(actions.contains(receiveSelector), "receiveButton should contain action")
  }

  func testScanButtonContainsAction() {
    let actions = self.sut.scanButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let scanSelector = #selector(CalculatorViewController.didTapScan(_:)).description
    XCTAssertTrue(actions.contains(scanSelector), "scanButton should contain action")
  }

  func testPayButtonContainsAction() {
    let actions = self.sut.sendButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let sendSelector = #selector(CalculatorViewController.didTapSend(_:)).description
    XCTAssertTrue(actions.contains(sendSelector), "sendButton should contain action")
  }

  // MARK: actions produce results
  func testTappingMenuTellsCoordinator() {
    self.sut.generalCoordinationDelegate = mockCoordinator

    self.sut.balanceContainer.leftButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.didTapMenuWasCalled)
  }

  func testTappingScanTellsCoordinator() {
    self.sut.scanButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.didTapScanWasCalled)
  }

  func testTappingRequestTellsCoordinator() {
    self.sut.receiveButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.didTapReceiveWasCalled)
  }

  func testTappingPayTellsCoordinator() {
    self.sut.sendButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.didTapSendWasCalled)
  }

  // MARK: first launch
  func testFetchingLastExchangeRateTellsDelegate() {
    mockCoordinator.latestExchangeRatesWasCalled = false

    self.sut.viewDidAppear(false)

    XCTAssertTrue(mockCoordinator.latestExchangeRatesWasCalled)
  }

  // MARK: custom mocks
  class MockCoordinator: CalculatorViewControllerDelegate {
    func isSyncCurrentlyRunning() -> Bool {
      return true
    }

    func viewControllerDidTapSendPaymentWithInvalidAmount(_ viewController: UIViewController, error: ValidatorTypeError) {}

    func latestFees() -> Promise<Fees> {
      return Promise { _ in }
    }

    func badgingManager() -> BadgeManagerType {
      return BadgeManager(persistenceManager: MockPersistenceManager())
    }

    let balanceUpdateManager = BalanceUpdateManager()

    func balanceNetPending() -> NSDecimalNumber {
      return .zero
    }

    func spendableBalanceNetPending() -> NSDecimalNumber {
      return .zero
    }

    var wasToldToEnterActiveState = false
    func requireAuthenticationIfNeeded(whenAuthenticated: (() -> Void)?) {
      wasToldToEnterActiveState = true
    }

    var didTapMenuWasCalled = false
    func containerDidTapLeftButton(in viewController: UIViewController) {
      didTapMenuWasCalled = true
    }

    func containerDidTapBalances(in viewController: UIViewController) {
      //
    }

    func containerDidLongPressBalances(in viewController: UIViewController) {
      //
    }

    var didTapScanWasCalled = false
    func viewControllerDidTapScan(_ viewController: UIViewController, converter: CurrencyConverter) {
      didTapScanWasCalled = true
    }

    var didTapReceiveWasCalled = false
    func viewControllerDidTapReceivePayment(_ viewController: UIViewController, converter: CurrencyConverter) {
      didTapReceiveWasCalled = true
    }

    var didTapSendWasCalled = false
    func viewControllerDidTapSendPayment(_ viewController: UIViewController, converter: CurrencyConverter) {
      didTapSendWasCalled = true
    }

    var latestExchangeRatesWasCalled = false
    func latestExchangeRates(responseHandler: ExchangeRatesRequest) {
      latestExchangeRatesWasCalled = true
    }

    func viewControllerDidRequestBadgeUpdate(_ viewController: UIViewController) {
    }

    func selectedCurrency() -> SelectedCurrency {
      return .BTC
    }
  }
}
