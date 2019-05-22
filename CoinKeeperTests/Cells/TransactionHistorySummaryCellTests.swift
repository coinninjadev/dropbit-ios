//
//  TransactionHistoryCellTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 4/11/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PhoneNumberKit
@testable import DropBit
import XCTest

class TransactionHistorySummaryCellTests: XCTestCase {
  var sut: TransactionHistorySummaryCell!

  let phoneNumberKit = PhoneNumberKit()

  override func setUp() {
    super.setUp()
    self.sut = TransactionHistorySummaryCell.nib().instantiate(withOwner: self, options: nil).first as? TransactionHistorySummaryCell
    self.sut.awakeFromNib()
  }

  private var testPayloadDTO: SharedPayloadDTO {
    return SharedPayloadDTO(addressPubKeyState: .none, sharingDesired: false, memo: "test memo", amountInfo: nil)
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.incomingImage, "incomingImage should be connected")
    XCTAssertNotNil(self.sut.receiverLabel, "receiverLabel should be connected")
    XCTAssertNotNil(self.sut.statusLabel, "statusLabel should be connected")
    XCTAssertNotNil(self.sut.dateLabel, "dateLabel should be connected")
    XCTAssertNotNil(self.sut.memoLabel, "memoLabel should be connected")
    XCTAssertNotNil(self.sut.primaryAmountLabel, "primaryAmountLabel should be connected")
    XCTAssertNotNil(self.sut.secondaryAmountLabel, "secondaryAmountLabel should be connected")
  }

  // MARK: load method
  func testLoadMethodPopoulatesOutlets() {
    // given
    let expectedAddress = "3NNE2SY73JkrupbWKu6iVCsGjrcNKXH4hR"
    let otd = OutgoingTransactionData(
      txid: "123txid",
      dropBitType: .none,
      destinationAddress: expectedAddress,
      amount: 123_456,
      feeAmount: 300,
      sentToSelf: false,
      requiredFeeRate: nil,
      sharedPayloadDTO: testPayloadDTO)
    let viewModel = sampleData(with: otd)

    // when
    self.sut.load(with: viewModel)

    // then
    XCTAssertEqual(self.sut.receiverLabel.text, expectedAddress, "receiverLabel text should be populated")
    XCTAssertEqual(self.sut.statusLabel.text, "Pending", "statusLabel should be populated")
    XCTAssertEqual(self.sut.dateLabel.text, viewModel.dateDescriptionFull, "dateLabel should be populated")
    XCTAssertEqual(self.sut.memoLabel.text, viewModel.memo, "memoLabel should be populated")

    let primary = "$8.66"
    XCTAssertEqual(self.sut.primaryAmountLabel.text, primary, "primaryAmountLabel should be populated")

    let secondary = "\(CurrencyCode.BTC.symbol)0.00123756"
    XCTAssertEqual(self.sut.secondaryAmountLabel.text, secondary, "secondaryAmountLabel should be populated")
  }

  func testLoadMethodWithTemporaryContactTransactionPopulatesOutlets() {
    // given
    let expectedAddress = "3NNE2SY73JkrupbWKu6iVCsGjrcNKXH4hR"
    let expectedName = "Indiana Jones"
    let number = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212")
    let phoneContact = ValidatedContact(kind: .invite, displayName: expectedName, displayNumber: number.asE164(), globalPhoneNumber: number)
    let dropBitType = OutgoingTransactionDropBitType.phone(phoneContact)
    let otd = OutgoingTransactionData(
      txid: "123txid",
      dropBitType: dropBitType,
      destinationAddress: expectedAddress,
      amount: 123_456,
      feeAmount: 300,
      sentToSelf: false,
      requiredFeeRate: nil,
      sharedPayloadDTO: testPayloadDTO)
    let viewModel = sampleData(with: otd)

    // when
    self.sut.load(with: viewModel)

    // then
    XCTAssertEqual(self.sut.receiverLabel.text, expectedName, "receiverLabel text should be populated with expected name")
    XCTAssertEqual(self.sut.statusLabel.text, "Pending", "statusLabel should be populated")
    XCTAssertEqual(self.sut.dateLabel.text, viewModel.dateDescriptionFull, "dateLabel should be populated")
    XCTAssertEqual(self.sut.memoLabel.text, viewModel.memo, "memoLabel should be populated")

    let primary = "$8.66"
    XCTAssertEqual(self.sut.primaryAmountLabel.text, primary, "primaryAmountLabel should be populated")

    let secondary = "\(CurrencyCode.BTC.symbol)0.00123756"
    XCTAssertEqual(self.sut.secondaryAmountLabel.text, secondary, "secondaryAmountLabel should be populated")
  }

  func testLoadMethodWithTemporaryPhoneNumberTransactionPopulatesOutlets() {
    // given
    let expectedAddress = "3NNE2SY73JkrupbWKu6iVCsGjrcNKXH4hR"
    let unformattedPhone = "3305551212"
    let formattedPhone = "+1 330-555-1212"
    let number = GlobalPhoneNumber(countryCode: 1, nationalNumber: unformattedPhone)
    let phoneContact = GenericContact(phoneNumber: number, formatted: formattedPhone)
    let dropBitType = OutgoingTransactionDropBitType.phone(phoneContact)
    let otd = OutgoingTransactionData(
      txid: "123txid",
      dropBitType: dropBitType,
      destinationAddress: expectedAddress,
      amount: 123_456,
      feeAmount: 300,
      sentToSelf: false,
      requiredFeeRate: nil,
      sharedPayloadDTO: testPayloadDTO)

    let viewModel = sampleData(with: otd)

    // when
    self.sut.load(with: viewModel)

    // then
    XCTAssertEqual(self.sut.receiverLabel.text, formattedPhone, "receiverLabel text should be populated with expected phone")
    XCTAssertEqual(self.sut.statusLabel.text, "Pending", "statusLabel should be populated")
    XCTAssertEqual(self.sut.dateLabel.text, viewModel.dateDescriptionFull, "dateLabel should be populated")
    XCTAssertEqual(self.sut.memoLabel.text, viewModel.memo, "memoLabel should be populated")

    let primary = "$8.66"
    XCTAssertEqual(self.sut.primaryAmountLabel.text, primary, "primaryAmountLabel should be populated")

    let secondary = "\(CurrencyCode.BTC.symbol)0.00123756"
    XCTAssertEqual(self.sut.secondaryAmountLabel.text, secondary, "secondaryAmountLabel should be populated")
  }

  func testLoadMethodWithTemporaryRegularTransactionPopulatesOutlets() {
    // given
    let expectedAddress = "3NNE2SY73JkrupbWKu6iVCsGjrcNKXH4hR"
    let otd = OutgoingTransactionData(
      txid: "123txid",
      dropBitType: .none,
      destinationAddress: expectedAddress,
      amount: 123_456,
      feeAmount: 300,
      sentToSelf: false,
      requiredFeeRate: nil,
      sharedPayloadDTO: testPayloadDTO)
    let viewModel = sampleData(with: otd)

    // when
    self.sut.load(with: viewModel)

    // then
    XCTAssertEqual(self.sut.receiverLabel.text, expectedAddress, "receiverLabel text should be populated")
    XCTAssertEqual(self.sut.statusLabel.text, "Pending", "statusLabel should be populated")
    XCTAssertEqual(self.sut.dateLabel.text, viewModel.dateDescriptionFull, "dateLabel should be populated")
    XCTAssertEqual(self.sut.memoLabel.text, viewModel.memo, "memoLabel should be populated")

    let primary = "$8.66"
    XCTAssertEqual(self.sut.primaryAmountLabel.text, primary, "primaryAmountLabel should be populated")

    let secondary = "\(CurrencyCode.BTC.symbol)0.00123756"
    XCTAssertEqual(self.sut.secondaryAmountLabel.text, secondary, "secondaryAmountLabel should be populated")
  }

  // MARK: private methods
  private func sampleData(with otd: OutgoingTransactionData, phoneFormat: PhoneNumberFormat = .national) -> TransactionHistoryDetailCellViewModel {
    let stack = InMemoryCoreDataStack()
    let transaction = CKMTransaction.findOrCreate(with: otd, in: stack.context)
    let rates: ExchangeRates = [.BTC: 1, .USD: 7000]

    let viewModel = TransactionHistoryDetailCellViewModel(
      transaction: transaction,
      rates: rates,
      primaryCurrency: .USD,
      deviceCountryCode: nil,
      kit: PhoneNumberKit()
    )

    return viewModel
  }
}
