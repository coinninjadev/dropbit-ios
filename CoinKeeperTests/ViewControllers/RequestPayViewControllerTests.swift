//
//  RequestPayViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 4/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PromiseKit
@testable import DropBit
import XCTest

class RequestPayViewControllerTests: XCTestCase {
  var sut: RequestPayViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    mockCoordinator = MockCoordinator()
    self.sut = RequestPayViewController.newInstance(delegate: mockCoordinator, viewModel: nil, alertManager: nil)
    _ = self.sut.view

    UIPasteboard.general.string = ""
  }

  override func tearDown() {
    self.mockCoordinator = nil
    self.sut = nil
    UIPasteboard.general.string = ""
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(self.sut.editAmountView, "currencyEditSwapView should be connected")
    XCTAssertNotNil(self.sut.qrImageView, "qrImageView should be connected")
    XCTAssertNotNil(self.sut.receiveAddressLabel, "receiveAddressLabel should be connected")
    XCTAssertNotNil(self.sut.receiveAddressTapGesture, "receiveAddressTapGesture should be connected")
    XCTAssertNotNil(self.sut.tapInstructionLabel, "tapInstructionLabel should be connected")
    XCTAssertNotNil(self.sut.bottomActionButton, "sendRequestButton should be connected")
    XCTAssertNotNil(self.sut.walletToggleView, "walletToggleView should be connected")
    XCTAssertNotNil(self.sut.memoLabel, "memoLabel should be connected")
    XCTAssertNotNil(self.sut.memoTextField, "memoTextField should be connected")
  }

  // MARK: buttons contain actions
  func testCloseButtonContainsAction() {
    let actions = self.sut.closeButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let closeSelector = #selector(RequestPayViewController.closeButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(closeSelector), "closeButton should contain action")
  }

  func testSendRequestButtonContainsAction() {
    let actions = self.sut.bottomActionButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let sendSelector = #selector(RequestPayViewController.sendRequestButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(sendSelector), "sendRequestButton should contain action")
  }

  // MARK: actions produce results
  func testCloseButtonTappedTellsDelegate() {
    self.sut.closeButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.didSelectCloseWasCalled, "closeButtonTapped should tell delegate to close")
  }

  func testSendRequestButtonTappedTellsDelegate() {
    self.sut.qrImageView.image = UIImage(named: "fakeQRCode")

    self.sut.bottomActionButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.didSelectSendRequestWasCalled, "sendRequestButton should tell delegate")
    XCTAssertEqual(mockCoordinator.payload.compactMap { $0 as? Data }.count, 1, "payload should contain image data")
  }

  func testTappingLabelCopiesAddress() {
    let sampleRates: ExchangeRates = [.BTC: 1, .USD: 7000]
    let address = "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu"
    let currencyPair = CurrencyPair(primary: .BTC, fiat: .USD)
    let swappableViewModel = CurrencySwappableEditAmountViewModel(exchangeRates: sampleRates,
                                                                  primaryAmount: 50,
                                                                  walletTransactionType: .onChain,
                                                                  currencyPair: currencyPair,
                                                                  delegate: nil)
    self.sut.viewModel = RequestPayViewModel(receiveAddress: address, amountViewModel: swappableViewModel)

    let tap = UITapGestureRecognizer()

    // initial
    XCTAssertEqual(UIPasteboard.general.string, "", "pasteboard should be empty")

    // when
    self.sut.addressTapped(tap)

    // then
    XCTAssertTrue(mockCoordinator.copiedToClipboardWasCalled, "should tell delegate that text was copied")

    if let pasteboardText = UIPasteboard.general.string, pasteboardText.isNotEmpty {
      XCTAssertEqual(pasteboardText, address, "pasteboard should contain only the address (actual text: \(pasteboardText))")

    } else {
      XCTFail("Pasteboard text is empty")
    }
  }

  // MARK: mock coordinator
  class MockCoordinator: RequestPayViewControllerDelegate {

    func viewControllerDidSelectCloseWithToggle(_ viewController: UIViewController) { }

    var didCreateInvoice = false
    func viewControllerDidCreateInvoice(_ viewController: UIViewController) {
      didCreateInvoice = true
    }

    var didSelectCreateInvoice = false
    func viewControllerDidSelectCreateInvoice(_ viewController: UIViewController,
                                              forAmount sats: Int,
                                              withMemo memo: String?) -> Promise<LNCreatePaymentRequestResponse> {
      didSelectCreateInvoice = true
      return Promise { _ in }
    }

    func latestExchangeRates(responseHandler: (ExchangeRates) -> Void) {}
    func latestFees() -> Promise<Fees> {
      return Promise { _ in }
    }

    func viewControllerDidRequestNextReceiveAddress(_ viewController: UIViewController) -> String? {
      return nil
    }

    var copiedToClipboardWasCalled = false
    func viewControllerSuccessfullyCopiedToClipboard(message: String, viewController: UIViewController) {
      copiedToClipboardWasCalled = true
    }

    var didSelectCloseWasCalled = false
    func viewControllerDidSelectClose(_ viewController: UIViewController) {
      didSelectCloseWasCalled = true
    }

    func viewControllerDidSelectClose(_ viewController: UIViewController, completion: CKCompletion? ) {
      didSelectCloseWasCalled = true
    }

    var didSelectSendRequestWasCalled = false
    var payload: [Any] = []
    func viewControllerDidSelectSendRequest(_ viewController: UIViewController, payload: [Any]) {
      didSelectSendRequestWasCalled = true
      self.payload = payload
    }

    func selectedCurrencyPair() -> CurrencyPair {
      return CurrencyPair(primary: .BTC, fiat: .USD)
    }

  }
}
