//
//  SendPaymentViewControllerTests.swift
//  CoinKeeperTests
//
//  Created by Mitchell Malleo on 4/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest
import PromiseKit
import PhoneNumberKit
import enum Result.Result

class SendPaymentViewControllerTests: XCTestCase {

  var sut: SendPaymentViewController!
  var mockCoordinator: MockSendPaymentViewControllerCoordinator!

  let phoneNumberKit = PhoneNumberKit()

  override func setUp() {
    super.setUp()
    self.sut = SendPaymentViewController.makeFromStoryboard()
    self.sut.viewModel = SendPaymentViewModel(btcAmount: 0.00567676,
                                              primaryCurrency: .USD,
                                              parser: CKRecipientParser(kit: self.phoneNumberKit),
                                              address: "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu")
    let mockNetworkManager = MockNetworkManager(persistenceManager: MockPersistenceManager())
    self.mockCoordinator = MockSendPaymentViewControllerCoordinator(networkManager: mockNetworkManager)
    self.sut.generalCoordinationDelegate = mockCoordinator
    _ = self.sut.view
  }

  override func tearDown() {
    sut = nil
    UIPasteboard.general.string = ""
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.payTitleLabel, "payTitleLabel should be connected")
    XCTAssertNotNil(self.sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(self.sut.primaryAmountTextField, "primaryAmountTextField should be connected")
    XCTAssertNotNil(self.sut.secondaryAmountLabel, "secondaryAmountLabel should be connected")
    XCTAssertNotNil(self.sut.phoneNumberEntryView, "phoneNumberEntryView should be connected")
    XCTAssertNotNil(self.sut.bitcoinAddressButton, "bitcoinAddressButton should be connected")
    XCTAssertNotNil(self.sut.recipientDisplayNameLabel, "recipientDisplayNameLabel should be connected")
    XCTAssertNotNil(self.sut.recipientDisplayNumberLabel, "recipientDisplayNumberLabel should be connected")
    XCTAssertNotNil(self.sut.pasteButton, "pasteButton should be connected")
    XCTAssertNotNil(self.sut.contactsButton, "contactsButton should be connected")
    XCTAssertNotNil(self.sut.scanButton, "scanButton should be connected")
    XCTAssertNotNil(self.sut.sendButton, "sendButton should be connected")
    XCTAssertNotNil(self.sut.memoContainerView, "memoButton should be connected")
  }

  // MARK: actionable outlets contain actions
  func testPasteButtonContainsAction() {
    let actions = self.sut.pasteButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let selector = #selector(SendPaymentViewController.performPaste).description
    XCTAssertTrue(actions.contains(selector), "pasteButton should contain action")
  }

  func testContactsButtonContainsAction() {
    let actions = self.sut.contactsButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let selector = #selector(SendPaymentViewController.performContacts).description
    XCTAssertTrue(actions.contains(selector), "contactsButton should contain action")
  }

  func testScanButtonContainsAction() {
    let actions = self.sut.scanButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let selector = #selector(SendPaymentViewController.performScan).description
    XCTAssertTrue(actions.contains(selector), "scanButton should contain action")
  }

  func testSendButtonContainsAction() {
    let actions = self.sut.sendButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let selector = #selector(SendPaymentViewController.performSend).description
    XCTAssertTrue(actions.contains(selector), "sendButton should contain action")
  }

  func testCloseButtonContainsAction() {
    let actions = self.sut.closeButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let selector = #selector(SendPaymentViewController.performClose).description
    XCTAssertTrue(actions.contains(selector), "closeButton should contain action")
  }

  func testBitcoinAddressButtonContainsAction() {
    let actions = self.sut.bitcoinAddressButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let selector = #selector(SendPaymentViewController.performStartPhoneEntry).description
    XCTAssertTrue(actions.contains(selector), "bitcoinAddressButton should contain action")
  }

  // MARK: actions produce results
  func testCloseButtonTappedProducesResult() {
    self.sut.closeButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.didTapClose)
  }

  func testPasteButtonTappedProducesResult() {
    self.sut.pasteButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.didTapPaste)
  }

  func testContactsButtonTappedProducesResult() {
    self.sut.contactsButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.didTapContacts)
  }

  func testScanButtonTappedProducesResult() {
    self.sut.scanButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.didTapScan)
  }

  func testBitcoinURLPasteWithoutAmount() {
    self.sut.viewModel.primaryCurrency = .USD

    let address = "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu"
    let text = "bitcoin:\(address)"
    self.sut.pasteRecipient(fromText: text)

    let expectation = XCTestExpectation(description: "update ui")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      XCTAssertEqual(self.sut.viewModel.primaryCurrency, .USD)

      XCTAssertTrue(self.sut.phoneNumberEntryView.isHidden)
      XCTAssertFalse(self.sut.bitcoinAddressButton.isHidden)
      XCTAssertEqual(self.sut.bitcoinAddressButton.title(for: .normal), address)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }

  func testBitcoinURLPasteWithAmount() {
    self.sut.viewModel.primaryCurrency = .USD

    let address = "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu"
    let text = "bitcoin:\(address)?amount=1.2"
    self.sut.pasteRecipient(fromText: text)
    XCTAssertEqual(self.sut.viewModel.primaryCurrency, .BTC)

    let expectation = XCTestExpectation(description: "update ui")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      XCTAssertEqual(self.sut.viewModel.primaryCurrency, .BTC)

      XCTAssertTrue(self.sut.phoneNumberEntryView.isHidden)
      XCTAssertFalse(self.sut.bitcoinAddressButton.isHidden)
      XCTAssertEqual(self.sut.bitcoinAddressButton.title(for: .normal), address)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }

  func testBitcoinURLPasteWithInvalidAmount() {
    self.sut.viewModel.primaryCurrency = .USD

    let address = "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu"
    let text = "bitcoin:\(address)?amount=1.2192384712893712893"
    self.sut.pasteRecipient(fromText: text)
    XCTAssertEqual(self.sut.viewModel.primaryCurrency, .BTC)

    let expectation = XCTestExpectation(description: "update ui")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      XCTAssertEqual(self.sut.viewModel.primaryCurrency, .BTC)

      XCTAssertTrue(self.sut.phoneNumberEntryView.isHidden)
      XCTAssertFalse(self.sut.bitcoinAddressButton.isHidden)
      XCTAssertEqual(self.sut.bitcoinAddressButton.title(for: .normal), address)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }

  func testBitcoinURLPasteWithInvalidAddress() {
    let text = "bitcoin:12A1MyfXbW6RhdRAZEqofac5jC?amount=1.2192384712893712893"
    self.sut.pasteRecipient(fromText: text)
    let title = "To: BTC Address or phone number"

    XCTAssertNil(self.sut.viewModel.paymentRecipient, "recipient should be nil after pasting invalid address")

    let expectation = XCTestExpectation(description: "update ui")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      XCTAssertTrue(self.sut.phoneNumberEntryView.isHidden)
      XCTAssertFalse(self.sut.bitcoinAddressButton.isHidden)
      XCTAssertEqual(self.sut.bitcoinAddressButton.title(for: .normal), title)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdateViewModelWithBitcoinRecipientSetsPrimaryCurrency() {
    guard let url = TestHelpers.mockValidBitcoinURL(withAmount: 1.2) else {
      XCTFail("Failed to create a BitcoinURL")
      return
    }

    let recipient = CKParsedRecipient.bitcoinURL(url)
    self.sut.updateViewModel(withParsedRecipient: recipient)
    XCTAssertEqual(self.sut.viewModel.primaryCurrency, .BTC)
  }

  // MARK: private classes
  class MockCoordinator: SendPaymentViewControllerDelegate {
    func showAlertForInvalidContactOrPhoneNumber(contactName: String?, displayNumber: String) {
    }

    func viewController(_ viewController: UIViewController, checkForContactFromGenericContact genericContact: GenericContact) -> ValidatedContact? {
      return nil
    }

    func deviceCountryCode() -> Int? {
      return nil
    }

    let networkManager: NetworkManagerType = MockNetworkManager(persistenceManager: MockPersistenceManager())

    func sendPaymentViewControllerDidLoad(_ viewController: UIViewController) {}

    func viewControllerDidRequestAlert(_ viewController: UIViewController, viewModel: AlertControllerViewModel) {}

    func balanceNetPending() -> NSDecimalNumber {
      return .zero
    }

    func spendableBalanceNetPending() -> NSDecimalNumber {
      return .zero
    }

    var balanceUpdateManager: BalanceUpdateManager

    init() {
      balanceUpdateManager = BalanceUpdateManager()
    }

    func latestExchangeRates(responseHandler: (ExchangeRates) -> Void) {

    }

    func latestFees(responseHandler: (Fees) -> Void) {

    }

    func latestFees() -> Promise<Fees> {
      return Promise.value([:])
    }

    var didTapScan = false
    func viewControllerDidPressScan(_ viewController: UIViewController, btcAmount: NSDecimalNumber, primaryCurrency: CurrencyCode) {
      didTapScan = true
    }

    var didTapContacts = false
    func viewControllerDidPressContacts(_ viewController: UIViewController & SelectedValidContactDelegate) {
      didTapContacts = true
    }

    func viewController(
      _ viewController: UIViewController,
      checkingCachedAddressesFor phoneNumberHash: String,
      completion: @escaping (Result<[WalletAddressesQueryResponse], UserProviderError>) -> Void) {

    }

    func viewControllerDidRequestVerificationCheck(_ viewController: UIViewController, completion: @escaping (() -> Void)) {

    }

    func viewControllerShouldInitiallyAllowMemoSharing(_ viewController: SendPaymentViewController) -> Bool {
      return true
    }

    var didTapClose = false
    func viewControllerDidSelectClose(_ viewController: UIViewController) {
      didTapClose = true
    }

    func viewControllerDidSendPayment(
      _ viewController: UIViewController,
      btcAmount: NSDecimalNumber,
      requiredFeeRate: Double?,
      primaryCurrency: CurrencyCode,
      address: String?,
      contact: ContactType?,
      rates: ExchangeRates,
      sharedPayload: SharedPayloadDTO) {

    }

    func viewControllerDidBeginAddressNegotiation(
      _ viewController: UIViewController,
      btcAmount: NSDecimalNumber,
      primaryCurrency: CurrencyCode,
      contact: ContactType,
      memo: String?,
      rates: ExchangeRates,
      memoIsShared: Bool,
      sharedPayload: SharedPayloadDTO) {

    }

    func viewControllerDidPasteInvalidDestination(_ viewController: UIViewController) {

    }

    func viewControllerDidAttemptInvalidDestination(_ viewController: UIViewController, error: Error?) {

    }

    var didTapPaste = false
    func viewControllerDidSelectPaste(_ viewController: UIViewController) {
      didTapPaste = true
    }

    var didSelectMemoButton = false
    func viewControllerDidSelectMemoButton(_ viewController: UIViewController, memo: String?, completion: @escaping (String) -> Void) {
      didSelectMemoButton = true
    }

    func openURL(_ url: URL, completionHandler completion: ((Bool) -> Void)?) { }
  }

}
