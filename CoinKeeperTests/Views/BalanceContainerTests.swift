//
//  BalanceContainerTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 4/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import PromiseKit
import XCTest

class BalanceContainerTests: XCTestCase {
  var sut: BalanceContainer!

  override func setUp() {
    super.setUp()
    let frame = CGRect(x: 0, y: 0, width: 375, height: 80)
    self.sut = BalanceContainer(frame: frame)

    _ = self.sut.xibSetup()

    let placeholder = PlaceholderViewController.makeFromStoryboard()
    placeholder.view.addSubview(self.sut)
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.leftButton, "leftButton should be connected")
    XCTAssertNotNil(self.sut.primaryAmountLabel, "primaryAmountLabel should be connected")
    XCTAssertNotNil(self.sut.secondaryAmountLabel, "secondaryAmountLabel should be connected")
    XCTAssertNotNil(self.sut.balancesTapGestureRecognizer, "balancesTapGestureRecognizer should be connected")
    XCTAssertNotNil(self.sut.balancesLongPressRecognizer, "balancesLongPressRecognizer should be connected")
  }

  // MARK: buttons contain actions
  func testLeftButtonContainsAction() {
    let actions = self.sut.leftButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let leftSelector = #selector(BalanceContainer.didTapLeftButton(_:)).description
    XCTAssertTrue(actions.contains(leftSelector), "leftButton should contain action")
  }

  // MARK: actions produce results
  func testLeftButtonTellsDelegate() {
    let mockDelegate = MockBalanceContainerDelegate()
    self.sut.delegate = mockDelegate

    self.sut.leftButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockDelegate.didTapLeftWasCalled, "leftButton should tell delegate it was called")
  }

  func testTappingBalanceTellsDelegate() {
    let mockDelegate = MockBalanceContainerDelegate()
    self.sut.delegate = mockDelegate

    self.sut.didTapRightGestureView(self.sut.balancesTapGestureRecognizer)

    XCTAssertTrue(mockDelegate.didTapBalanceWasCalled, "should tell delegate that balance was tapped")
  }

  func testLongPressingBalanceTellsDelegate() {
    let mockDelegate = MockBalanceContainerDelegate()
    self.sut.delegate = mockDelegate

    self.sut.didLongPressBalances(self.sut.balancesLongPressRecognizer)

    XCTAssertTrue(mockDelegate.didLongPressBalance, "should tell delegate that balance was long pressed")
  }

  // MARK: mock delegate
  class MockBalanceContainerDelegate: BalanceContainerDelegate {
    var didTapLeftWasCalled = false
    func containerDidTapLeftButton(in viewController: UIViewController) {
      didTapLeftWasCalled = true
    }

    func containerDidTapDropBitMe(in viewController: UIViewController) {}

    var didTapBalanceWasCalled = false
    func didTapRightGesture(in viewController: UIViewController) {
      didTapBalanceWasCalled = true
    }

    var didLongPressBalance = false
    func containerDidLongPressBalances(in viewController: UIViewController) {
      didLongPressBalance = true
    }

    var didCallIsSyncCurrentlyRunning = false
    func isSyncCurrentlyRunning() -> Bool {
      didCallIsSyncCurrentlyRunning = true
      return true
    }

    func selectedCurrency() -> SelectedCurrency {
      return .BTC
    }

    func dropBitMeAvatar() -> Promise<UIImage> {
      return Promise { _ in }
    }
  }
}
