//
//  TransactionHistoryDetailValidCellTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 4/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class TransactionHistoryDetailValidCellTests: XCTestCase {
  var sut: TransactionHistoryDetailValidCell!
  var mockCoordinator: MockTransactionHistoryDetailCellDelegate!

  override func setUp() {
    super.setUp()
    self.sut = TransactionHistoryDetailValidCell.nib().instantiate(withOwner: self, options: nil).first as? TransactionHistoryDetailValidCell
    self.sut.awakeFromNib()
    mockCoordinator = MockTransactionHistoryDetailCellDelegate()
    self.sut.delegate = mockCoordinator
  }

  override func tearDown() {
    mockCoordinator = nil
    sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.progressBarWidthConstraint, "progressBarWidthConstraint should be connected")
    XCTAssertNotNil(sut.progressView, "progressView should be connected")
    XCTAssertNotNil(sut.addressView, "addressView should be connected")
    XCTAssertNotNil(sut.bottomButton, "bottomButton should be connected")
    XCTAssertNotNil(sut.messageContainer, "messageContainer should be connected")
    XCTAssertNotNil(sut.messageLabel, "messageLabel should be connected")
    XCTAssertNotNil(sut.messageContainerHeightConstraint, "messageContainerHeightConstraint should be connected")
    XCTAssertNotNil(sut.bottomBufferView, "bottomBufferView should be connected")
    XCTAssertNotNil(sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(sut.questionMarkButton, "questionMarkButton should be connected")
    XCTAssertNotNil(sut.incomingImage, "incomingImage should be connected")
    XCTAssertNotNil(sut.dateLabel, "dateLabel should be connected")
    XCTAssertNotNil(sut.primaryAmountLabel, "primaryAmountLabel should be connected")
    XCTAssertNotNil(sut.secondaryAmountLabel, "secondaryAmountLabel should be connected")
    XCTAssertNotNil(sut.historicalValuesLabel, "historicalValuesLabel should be connected")
    XCTAssertNotNil(sut.addMemoButton, "addMemoButton should be connected")
    XCTAssertNotNil(sut.memoContainerView, "memoContainerView should be connected")
    XCTAssertNotNil(sut.statusLabel, "statusLabel should be connected")
    XCTAssertNotNil(sut.counterpartyLabel, "counterpartyLabel should be connected")
    XCTAssertNotNil(sut.underlyingContentView, "underlyingContentView should be connected")
  }

  // MARK: buttons contain actions
  func testAddMemoButtonContainsAction() {
    let actions = sut.addMemoButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(TransactionHistoryDetailInvalidCell.didTapAddMemoButton(_:)).description
    XCTAssertTrue(actions.contains(expected), "button should contain action")
  }

  func testCloseButtonContainsAction() {
    let actions = sut.closeButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(TransactionHistoryDetailInvalidCell.didTapClose(_:)).description
    XCTAssertTrue(actions.contains(expected), "button should contain action")
  }

  func testQuestionMarkButtonContainsAction() {
    let actions = sut.questionMarkButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(TransactionHistoryDetailInvalidCell.didTapQuestionMarkButton(_:)).description
    XCTAssertTrue(actions.contains(expected), "button should contain action")
  }

  func testBottomButtonContainsAction() {
    let actions = sut.bottomButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(TransactionHistoryDetailValidCell.didTapBottomButton(_:)).description
    XCTAssertTrue(actions.contains(expected), "button should contain action")
  }

  // MARK: actions produce results
  func testCloseButtonTellsDelegate() {
    sut.closeButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.tappedClose)
  }

  func testQuestionMarkButtonTellsDelegate() {
    sut.questionMarkButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.tappedQuestionMark)
  }

  func testAddMemoButtonTellsDelegate() {
    sut.addMemoButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.tappedAddMemo)
  }

  func testBottomButtonTellsDelegate() {
    sut.bottomButton.tag = TransactionDetailAction.seeDetails.rawValue
    sut.didTapBottomButton(sut.bottomButton)
    XCTAssertTrue(mockCoordinator.tappedBottomButton)
  }

  // MARK: load
  func testLoadMethodPopulatesOutlets() {
    let mockDelegate = MockTransactionHistoryDetailCellDelegate()
    let data = self.sampleData()
    self.sut.load(with: data, delegate: mockDelegate)

    XCTAssertTrue(mockDelegate === sut.delegate)
    XCTAssertTrue(data === sut.viewModel)
    XCTAssertEqual(self.sut.counterpartyLabel.text, data.counterpartyDescription, "counterpartyLabel should contain description")
    XCTAssertEqual(self.sut.addressView.addressTextButton.title(for: .normal), data.receiverAddress, "addressLabel should equal receiverAddress")
    XCTAssertFalse(self.sut.addressView.isHidden, "addressView should not be hidden")
    XCTAssertEqual(self.sut.primaryAmountLabel.text, data.primaryAmountLabel, "primaryAmountLabel should be populated")
    XCTAssertEqual(self.sut.secondaryAmountLabel.attributedText?.string, data.secondaryAmountLabel?.string,
                   "secondaryAmountLabel should be populated")
    XCTAssertFalse(sut.addMemoButton.isHidden)
    XCTAssertEqual(self.sut.dateLabel.text, data.dateDescriptionFull, "dateLabel should be populated")
  }

  // MARK: private methods
  private func sampleData() -> TransactionHistoryDetailCellViewModel {
    var data: SampleTransaction!
    let satoshis: Int = 100_000
    let phoneNumber = SamplePhoneNumber(
      countryCode: 1,
      number: 123,
      phoneNumberHash: "",
      status: "",
      counterpartyName: SampleCounterpartyName(name: "John Giannandrea"))
    data = SampleTransaction(
      netWalletAmount: nil,
      id: "7f3a2790d59853fdc620b8cd23c8f68158f8bbdcd337a5f2451620d6f76d4e03",
      btcReceived: NSDecimalNumber(integerAmount: satoshis, currency: .BTC),
      isIncoming: false,
      walletAddress: SampleTransaction.sampleWalletAddress,
      confirmations: 4,
      date: Date.new(2018, 3, 3, time: 14, 30),
      counterpartyAddress: SampleCounterpartyAddress(addressId: "54b224e4eef004e66bdac46f13a80db56687262f0923be02ad0e9469496126ef"),
      phoneNumber: phoneNumber,
      invitation: nil
    )
    return data
  }
}
