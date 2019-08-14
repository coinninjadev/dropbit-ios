//
//  ConfirmPaymentViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 12/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import CNBitcoinKit

class ConfirmPaymentViewControllerTests: XCTestCase {

  var sut: ConfirmPaymentViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    mockCoordinator = MockCoordinator()
    sut = ConfirmPaymentViewController.makeFromStoryboard()
    sut.generalCoordinationDelegate = mockCoordinator
    _ = sut.view
  }

  override func tearDown() {
    sut = nil
    mockCoordinator = nil
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(sut.confirmView, "confirmView should be connected")
    XCTAssertNotNil(sut.networkFeeLabel, "networkFeeLabel should be connected")
    XCTAssertNotNil(sut.networkFeeLabel, "networkFeeLabel should be connected")
    XCTAssertNotNil(sut.contactLabel, "contactLabel should be connected")
    XCTAssertNotNil(sut.primaryAddressLabel, "primaryAddressLabel should be connected")
    XCTAssertNotNil(sut.secondaryAddressLabel, "secondaryAddressLabel should be connected")
    XCTAssertNotNil(sut.primaryCurrencyLabel, "primaryCurrencyLabel should be connected")
    XCTAssertNotNil(sut.secondaryCurrencyLabel, "secondaryCurrencyLabel should be connected")
    XCTAssertNotNil(sut.memoContainerView, "memoContainerView should be connected")
    XCTAssertNotNil(sut.avatarBackgroundView, "avatarBackgroundView should be connected")
    XCTAssertNotNil(sut.avatarImageView, "avatarImageView should be connected")
  }

  // MARK: buttons contain actions
  func testCloseButtonContainsAction() {
    let closeActions = sut.closeButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let closeSelector = #selector(ConfirmPaymentViewController.closeButtonWasTouched).description
    XCTAssertTrue(closeActions.contains(closeSelector), "closeButton should contain action")
  }

  class MockCoordinator: ConfirmPaymentViewControllerDelegate {
    func viewControllerDidConfirmPayment(
      _ viewController: UIKit.UIViewController,
      transactionData: CNBitcoinKit.CNBTransactionData,
      rates: ExchangeRates,
      outgoingTransactionData: OutgoingTransactionData
      ) {

    }

    func viewControllerRequestedShowFeeTooExpensiveAlert(_ viewController: UIViewController) { }

    func viewControllerDidConfirmInvite(_ viewController: UIViewController, outgoingInvitationDTO: OutgoingInvitationDTO) { }

    var closeButtonTapped = false
    func viewControllerDidSelectClose(_ viewController: UIViewController) {
      closeButtonTapped = true
    }

    func viewControllerDidSelectClose(_ viewController: UIViewController, completion: (() -> Void)? ) {
      closeButtonTapped = true
    }

    func confirmPaymentViewControllerDidLoad(_ viewController: UIViewController) { }
  }
}
