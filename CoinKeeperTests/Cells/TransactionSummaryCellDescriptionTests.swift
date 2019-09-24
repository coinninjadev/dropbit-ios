//
//  TransactionSummaryCellDescriptionTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 8/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

/// Primarily tests the prioritization of strings when multiple counterparty descriptors are available
class TransactionSummaryCellDescriptionTests: XCTestCase {
  var sut: TransactionHistorySummaryCell!

  override func setUp() {
    super.setUp()
    self.sut = TransactionHistorySummaryCell.nib().instantiate(withOwner: self, options: nil).first as? TransactionHistorySummaryCell
    self.sut.awakeFromNib()
  }

  let twitterConfig = MockSummaryCellVM.mockTwitterConfig()

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

  func testDescriptionLoadsName() {
    let expectedName = "Satoshi"
    let counterparty = TransactionCellCounterpartyConfig(displayName: expectedName)
    let viewModel = MockSummaryCellVM.testSummaryInstance(counterpartyConfig: counterparty)
    sut.configure(with: viewModel)
    XCTAssertEqual(sut.descriptionLabel.text, expectedName)
  }

  func testDescriptionLoadsLightningDeposit() {
    let lightningDepositVM = MockSummaryCellVM.testSummaryInstance(walletTxType: .onChain,
                                                                   direction: .out,
                                                                   isLightningTransfer: true,
                                                                   receiverAddress: expectedAddress,
                                                                   counterpartyConfig: fullCounterparty)
    let expectedDepositDescription = lightningDepositVM.lightningDepositText
    sut.configure(with: lightningDepositVM)
    XCTAssertEqual(sut.descriptionLabel.text, expectedDepositDescription)
  }

  func testDescriptionLoadsLightningWithdrawal() {
    let lightningWithdrawalVM = MockSummaryCellVM.testSummaryInstance(walletTxType: .lightning,
                                                                      direction: .out,
                                                                      isLightningTransfer: true,
                                                                      receiverAddress: expectedAddress,
                                                                      counterpartyConfig: fullCounterparty)
    let expectedWithdrawalDescription = lightningWithdrawalVM.lightningWithdrawText
    sut.configure(with: lightningWithdrawalVM)
    XCTAssertEqual(sut.descriptionLabel.text, expectedWithdrawalDescription)
  }

  func testDescriptionLoadsUnpaidLightningInvoice() {
    let lightningVM = MockSummaryCellVM.testSummaryInstance(walletTxType: .lightning,
                                                            direction: .in,
                                                            status: .pending,
                                                            isLightningTransfer: false,
                                                            lightningInvoice: TestHelpers.mockLightningInvoice(),
                                                            counterpartyConfig: nil)
    let expectedText = lightningVM.lightningUnpaidInvoiceText
    sut.configure(with: lightningVM)
    XCTAssertEqual(sut.descriptionLabel.text, expectedText)
  }

  func testDescriptionLoadsExpiredLightningInvoice() {
    let lightningVM = MockSummaryCellVM.testSummaryInstance(walletTxType: .lightning,
                                                            direction: .in,
                                                            status: .expired,
                                                            isLightningTransfer: false,
                                                            lightningInvoice: TestHelpers.mockLightningInvoice(),
                                                            counterpartyConfig: nil)
    let expectedText = lightningVM.lightningUnpaidInvoiceText
    sut.configure(with: lightningVM)
    XCTAssertEqual(sut.descriptionLabel.text, expectedText)
  }

  func testDescriptionLoadsPaidLightningInvoice() {
    let lightningVM = MockSummaryCellVM.testSummaryInstance(walletTxType: .lightning,
                                                            direction: .out,
                                                            status: .completed,
                                                            isLightningTransfer: false,
                                                            lightningInvoice: TestHelpers.mockLightningInvoice(),
                                                            counterpartyConfig: nil)
    let expectedText = lightningVM.lightningPaidInvoiceText
    sut.configure(with: lightningVM)
    XCTAssertEqual(sut.descriptionLabel.text, expectedText)
  }

  func testDescriptionLoadsTwitterHandle() {
    let twitterCounterparty = fullCounterparty
    let twitterVM = MockSummaryCellVM.testSummaryInstance(walletTxType: .onChain,
                                                          isLightningTransfer: false,
                                                          counterpartyConfig: twitterCounterparty)
    sut.configure(with: twitterVM)
    XCTAssertEqual(sut.descriptionLabel.text, expectedTwitterHandle)
  }

  func testDescriptionLoadsDisplayName() {
    let counterparty = TransactionCellCounterpartyConfig(displayName: expectedName,
                                                         displayPhoneNumber: expectedPhoneNumber,
                                                         twitterConfig: nil)
    let nameVM = MockSummaryCellVM.testSummaryInstance(counterpartyConfig: counterparty)
    sut.configure(with: nameVM)
    XCTAssertEqual(sut.descriptionLabel.text, expectedName)
  }

  func testDescriptionLoadsPhoneNumber() {
    let phoneCounterparty = TransactionCellCounterpartyConfig(displayName: nil,
                                                              displayPhoneNumber: expectedPhoneNumber,
                                                              twitterConfig: nil)
    let phoneVM = MockSummaryCellVM.testSummaryInstance(walletTxType: .lightning,
                                                        direction: .out,
                                                        isLightningTransfer: false,
                                                        counterpartyConfig: phoneCounterparty)
    sut.configure(with: phoneVM)
    XCTAssertEqual(sut.descriptionLabel.text, expectedPhoneNumber)
  }

  func testDescriptionLoadsBitcoinAddress() {
    let addressVM = MockSummaryCellVM.testSummaryInstance(walletTxType: .onChain,
                                                          direction: .in,
                                                          isLightningTransfer: false,
                                                          receiverAddress: expectedAddress,
                                                          counterpartyConfig: nil)
    sut.configure(with: addressVM)
    XCTAssertEqual(sut.descriptionLabel.text, expectedAddress)
  }

}
