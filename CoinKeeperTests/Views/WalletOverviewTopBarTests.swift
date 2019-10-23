//
//  WalletOverviewTopBarTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 4/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import PromiseKit
import XCTest

class WalletOverviewTopBarTests: XCTestCase {
  var sut: WalletOverviewTopBar!

  override func setUp() {
    super.setUp()
    let frame = CGRect(x: 0, y: 0, width: 375, height: 80)
    self.sut = WalletOverviewTopBar(frame: frame)

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
    XCTAssertNotNil(self.sut.balanceView, "balanceView should be connected")
    XCTAssertNotNil(self.sut.rightBalanceContainerView, "rightBalanceContainerView should be connected")
  }

  // MARK: buttons contain actions
  func testLeftButtonContainsAction() {
    let actions = self.sut.leftButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let leftSelector = #selector(WalletOverviewTopBar.didTapLeftButton(_:)).description
    XCTAssertTrue(actions.contains(leftSelector), "leftButton should contain action")
  }

  // MARK: actions produce results
  func testLeftButtonTellsDelegate() {
    let mockDelegate = MockBalanceContainerDelegate()
    self.sut.delegate = mockDelegate

    self.sut.leftButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockDelegate.didTapLeftWasCalled, "leftButton should tell delegate it was called")
  }

  func testTappingChartsButton() {
    let mockDelegate = MockBalanceContainerDelegate()
    self.sut.delegate = mockDelegate

    self.sut.didTapChartsButton()

    XCTAssertTrue(mockDelegate.didTapChartsButtonWasCalled, "should tell delegate that charts was pressed")
  }

  // MARK: mock delegate
  class MockBalanceContainerDelegate: WalletOverviewTopBarDelegate {

    var didTapChartsButtonWasCalled = false
    func didTapChartsButton() {
      didTapChartsButtonWasCalled = true
    }

    var selectedWalletTransactionTypeWasCalled = false
    func selectedWalletTransactionType() -> WalletTransactionType {
      selectedWalletTransactionTypeWasCalled = true
      return .onChain
    }

    var didTapLeftWasCalled = false
    func containerDidTapLeftButton(in viewController: UIViewController) {
      didTapLeftWasCalled = true
    }

    func containerDidTapDropBitMe(in viewController: UIViewController) {}

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
