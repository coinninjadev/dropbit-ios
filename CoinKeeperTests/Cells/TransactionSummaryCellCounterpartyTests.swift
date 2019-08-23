//
//  TransactionSummaryCellCounterpartyTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 8/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

/// Primarily tests the prioritization of strings when multiple counterparty descriptors are available
class TransactionSummaryCellCounterpartyTests: XCTestCase {
  var sut: TransactionHistorySummaryCell!

  override func setUp() {
    super.setUp()
    self.sut = TransactionHistorySummaryCell.nib().instantiate(withOwner: self, options: nil).first as? TransactionHistorySummaryCell
    self.sut.awakeFromNib()
  }

  let twitterConfig = MockSummaryCellVM.testTwitterConfig()

  var expectedTwitterHandle: String {
    return twitterConfig.displayHandle
  }

  let expectedName = "Satoshi"
  let expectedAddress = TestHelpers.mockValidBitcoinAddress()
  let expectedPhoneNumber = "(123) 456-7890"

  /// This object would never exist with both a phone number and Twitter config, but it's useful for proving priority
  var fullCounterparty: TransactionCellCounterpartyConfig {
    return TransactionCellCounterpartyConfig(displayName: expectedName,
                                             displayPhoneNumber: expectedPhoneNumber,
                                             twitterConfig: twitterConfig)
  }

  func testCounterpartyLoadsName() {
    let expectedName = "Satoshi"
    let counterparty = TransactionCellCounterpartyConfig(displayName: expectedName)
    let viewModel = MockSummaryCellVM.testInstance(counterpartyConfig: counterparty)
    sut.configure(with: viewModel)
    XCTAssertEqual(sut.counterpartyLabel.text, expectedName)
  }

  func testCounterpartyLoadsLightningDeposit() {
    let lightningDepositVM = MockSummaryCellVM.testInstance(walletTxType: .onChain,
                                                            direction: .out,
                                                            isLightningTransfer: true,
                                                            btcAddress: expectedAddress,
                                                            counterpartyConfig: fullCounterparty)
    let expectedDepositDescription = lightningDepositVM.lightningDepositText
    sut.configure(with: lightningDepositVM)
    XCTAssertEqual(sut.counterpartyLabel.text, expectedDepositDescription)
  }

  func testCounterpartyLoadsLightningWithdrawal() {
    let lightningWithdrawalVM = MockSummaryCellVM.testInstance(walletTxType: .lightning,
                                                               direction: .out,
                                                               isLightningTransfer: true,
                                                               btcAddress: expectedAddress,
                                                               counterpartyConfig: fullCounterparty)
    let expectedWithdrawalDescription = lightningWithdrawalVM.lightningWithdrawText
    sut.configure(with: lightningWithdrawalVM)
    XCTAssertEqual(sut.counterpartyLabel.text, expectedWithdrawalDescription)
  }

  func testCounterpartyLoadsUnpaidLightningInvoice() {
    let lightningVM = MockSummaryCellVM.testInstance(walletTxType: .lightning,
                                                     direction: .in,
                                                     status: .pending,
                                                     isLightningTransfer: false,
                                                     lightningInvoice: TestHelpers.mockLightningInvoice(),
                                                     counterpartyConfig: nil)
    let expectedText = lightningVM.lightningUnpaidInvoiceText
    sut.configure(with: lightningVM)
    XCTAssertEqual(sut.counterpartyLabel.text, expectedText)
  }

  func testCounterpartyLoadsExpiredLightningInvoice() {
    let lightningVM = MockSummaryCellVM.testInstance(walletTxType: .lightning,
                                                     direction: .in,
                                                     status: .expired,
                                                     isLightningTransfer: false,
                                                     lightningInvoice: TestHelpers.mockLightningInvoice(),
                                                     counterpartyConfig: nil)
    let expectedText = lightningVM.lightningUnpaidInvoiceText
    sut.configure(with: lightningVM)
    XCTAssertEqual(sut.counterpartyLabel.text, expectedText)
  }

  func testCounterpartyLoadsPaidLightningInvoice() {
    let lightningVM = MockSummaryCellVM.testInstance(walletTxType: .lightning,
                                                     direction: .out,
                                                     status: .completed,
                                                     isLightningTransfer: false,
                                                     lightningInvoice: TestHelpers.mockLightningInvoice(),
                                                     counterpartyConfig: nil)
    let expectedText = lightningVM.lightningPaidInvoiceText
    sut.configure(with: lightningVM)
    XCTAssertEqual(sut.counterpartyLabel.text, expectedText)
  }

  func testCounterpartyLoadsDisplayName() {
    let nameVM = MockSummaryCellVM.testInstance(counterpartyConfig: fullCounterparty)
    sut.configure(with: nameVM)
    XCTAssertEqual(sut.counterpartyLabel.text, expectedName)
  }

  func testCounterpartyLoadsTwitterHandle() {
    let twitterCounterparty = TransactionCellCounterpartyConfig(displayName: nil,
                                                                displayPhoneNumber: nil,
                                                                twitterConfig: twitterConfig)
    let twitterVM = MockSummaryCellVM.testInstance(walletTxType: .onChain,
                                                   isLightningTransfer: false,
                                                   counterpartyConfig: twitterCounterparty)
    sut.configure(with: twitterVM)
    XCTAssertEqual(sut.counterpartyLabel.text, expectedTwitterHandle)
  }

  func testCounterpartyLoadsPhoneNumber() {
    let phoneCounterparty = TransactionCellCounterpartyConfig(displayName: nil,
                                                              displayPhoneNumber: expectedPhoneNumber,
                                                              twitterConfig: nil)
    let phoneVM = MockSummaryCellVM.testInstance(walletTxType: .lightning,
                                                 direction: .out,
                                                 isLightningTransfer: false,
                                                 counterpartyConfig: phoneCounterparty)
    sut.configure(with: phoneVM)
    XCTAssertEqual(sut.counterpartyLabel.text, expectedPhoneNumber)
  }

  func testCounterpartyLoadsBitcoinAddress() {
    let addressVM = MockSummaryCellVM.testInstance(walletTxType: .onChain,
                                                   direction: .in,
                                                   isLightningTransfer: false,
                                                   btcAddress: expectedAddress,
                                                   counterpartyConfig: nil)
    sut.configure(with: addressVM)
    XCTAssertEqual(sut.counterpartyLabel.text, expectedAddress)
  }

}
