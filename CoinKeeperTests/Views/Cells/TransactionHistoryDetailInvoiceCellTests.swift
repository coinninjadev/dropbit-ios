//
//  TransactionHistoryDetailInvoiceCellTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

//swiftlint:disable weak_delegate
class TransactionHistoryDetailInvoiceCellTests: XCTestCase {
  var sut: TransactionHistoryDetailInvoiceCell!
  var mockDelegate: MockTransactionHistoryDetailCellDelegate!

  override func setUp() {
    super.setUp()
    self.sut = TransactionHistoryDetailInvoiceCell.nib().instantiate(withOwner: self, options: nil).first as? TransactionHistoryDetailInvoiceCell
    self.sut.awakeFromNib()
    mockDelegate = MockTransactionHistoryDetailCellDelegate()
    self.sut.delegate = mockDelegate
  }

  override func tearDown() {
    mockDelegate = nil
    sut = nil
    super.tearDown()
  }

  func testInvoiceCellOutletsAreConnected() {
    XCTAssertNotNil(sut.underlyingContentView, "underlyingContentView should be connected")
    XCTAssertNotNil(sut.questionMarkButton, "questionMarkButton should be connected")
    XCTAssertNotNil(sut.titleLabel, "titleLabel should be connected")
    XCTAssertNotNil(sut.expirationLabel, "expirationLabel should be connected")
    XCTAssertNotNil(sut.invoiceAmountContainer, "invoiceAmountContainer should be connected")
    XCTAssertNotNil(sut.primaryAmountLabel, "primaryAmountLabel should be connected")
    XCTAssertNotNil(sut.secondaryAmountLabel, "secondaryAmountLabel should be connected")
    XCTAssertNotNil(sut.qrHistoricalContainer, "qrHistoricalContainer should be connected")
    XCTAssertNotNil(sut.qrCodeImageView, "qrCodeImageView should be connected")
    XCTAssertNotNil(sut.historicalValuesLabel, "historicalValuesLabel should be connected")
    XCTAssertNotNil(sut.memoLabel, "memoLabel should be connected")
    XCTAssertNotNil(sut.copyInvoiceView, "copyInvoiceView should be connected")
    XCTAssertNotNil(sut.copyInvoiceLabel, "copyInvoiceLabel should be connected")
    XCTAssertNotNil(sut.bottomButton, "bottomButton should be connected")
    XCTAssertNotNil(sut.dateLabel, "dateLabel should be connected")
  }

}
