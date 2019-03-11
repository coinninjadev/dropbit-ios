//
//  TransactionHistoryDetailCellTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 4/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class TransactionHistoryDetailCellTests: XCTestCase {
  var sut: TransactionHistoryDetailCell!

  override func setUp() {
    super.setUp()
    self.sut = TransactionHistoryDetailCell.nib().instantiate(withOwner: self, options: nil).first as? TransactionHistoryDetailCell
    self.sut.awakeFromNib()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.incomingImage, "incomingImage should be connected")
    XCTAssertNotNil(self.sut.statusLabel, "statusLabel should be connected")
    XCTAssertNotNil(self.sut.counterpartyLabel, "counterpartyLabel should be connected")
    XCTAssertNotNil(self.sut.addressView, "addressView should be connected")
    XCTAssertNotNil(self.sut.primaryAmountLabel, "primaryAmountLabel should be connected")
    XCTAssertNotNil(self.sut.secondaryAmountLabel, "secondaryAmountLabel should be connected")
    XCTAssertNotNil(self.sut.historicalValuesLabel, "historicalValuesLabel should be connected")
    XCTAssertNotNil(self.sut.dateLabel, "dateLabel should be connected")
    XCTAssertNotNil(self.sut.bottomButtonContainer, "bottomButtonContainer should be connected")
    XCTAssertNotNil(self.sut.bottomButton, "bottomButton should be connected")
    XCTAssertNotNil(self.sut.bottomStackView, "bottomStackView should be connected")
    XCTAssertNotNil(self.sut.bottomStackViewHeightConstraint, "bottomStackViewHeightConstraint should be connected")
    XCTAssertNotNil(self.sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(self.sut.questionMarkButton, "questionMarkButton should be connected")
  }

  // MARK: buttons contain actions
  func testShareButtonContainsAction() {
    let actions = self.sut.bottomButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let shareSelector = #selector(TransactionHistoryDetailCell.didTapBottomButton(_:)).description
    XCTAssertTrue(actions.contains(shareSelector), "actionButton should contain action")
  }

  func testCloseButtonContainsAction() {
    let actions = self.sut.closeButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let closeSelector = #selector(TransactionHistoryDetailCell.didTapClose(_:)).description
    XCTAssertTrue(actions.contains(closeSelector), "closeButton should contain action")
  }

  // MARK: actions produce results
  func testShareButtonTellsDelegate() {
    let mockDelegate = MockTransactionHistoryDetailCellDelegate()
    self.sut.load(with: self.sampleData(), delegate: mockDelegate)

    self.sut.bottomButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockDelegate.tappedBottomButton, "bottomButton should tell delegate it was tapped")
    XCTAssertEqual(mockDelegate.transactionDetailAction, TransactionDetailAction.seeDetails)
  }

  func testCloseButtonTellsDelegate() {
    let mockDelegate = MockTransactionHistoryDetailCellDelegate()
    self.sut.load(with: self.sampleData(), delegate: mockDelegate)

    self.sut.closeButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockDelegate.tappedClose, "bottomButton should tell delegate it was tapped")
  }

  // MARK: load method
  func testLoadMethodPopulatesOutlets() {
    let mockDelegate = MockTransactionHistoryDetailCellDelegate()
    let data = self.sampleData()
    self.sut.load(with: data, delegate: mockDelegate)

    XCTAssertEqual(self.sut.counterpartyLabel.text, data.counterpartyDescription, "counterpartyLabel should contain description")
    XCTAssertEqual(self.sut.addressView.addressTextButton.title(for: .normal), data.receiverAddress, "addressLabel should equal receiverAddress")
    XCTAssertFalse(self.sut.addressView.isHidden, "addressView should not be hidden")
    XCTAssertEqual(self.sut.primaryAmountLabel.text, data.primaryAmountLabel, "primaryAmountLabel should be populated")
    XCTAssertEqual(self.sut.secondaryAmountLabel.attributedText?.string, data.secondaryAmountLabel?.string,
                   "secondaryAmountLabel should be populated")
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
