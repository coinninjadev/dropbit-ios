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

  override func setUp() {
    super.setUp()
    self.sut = TransactionHistorySummaryCell.nib().instantiate(withOwner: self, options: nil).first as? TransactionHistorySummaryCell
    self.sut.awakeFromNib()
  }

  func createTestViewModel(walletTxType: WalletTransactionType = .onChain,
                           direction: TransactionDirection = .out,
                           isValid: Bool = true,
                           status: TransactionStatus = .completed,
                           date: Date = Date(),
                           isLightningTransfer: Bool = false,
                           selectedCurrency: SelectedCurrency = .fiat,
                           amountDetails: TransactionAmountDetails? = nil,
                           counterpartyDescription: String? = nil,
                           twitterConfig: TransactionCellTwitterConfig? = nil,
                           memo: String? = nil) -> MockTransactionSummaryCellViewModel {

    let amtDetails = amountDetails ?? MockTransactionSummaryCellViewModel.testAmountDetails(sats: 49500)
    return MockTransactionSummaryCellViewModel(
      walletTxType: walletTxType, direction: direction, isValid: isValid,
      status: status, date: date, isLightningTransfer: isLightningTransfer,
      selectedCurrency: selectedCurrency, amountDetails: amtDetails,
      counterpartyDescription: counterpartyDescription, twitterConfig: twitterConfig, memo: memo)
  }

  func createTestTwitterConfig() -> TransactionCellTwitterConfig {
    let avatar = UIImage(named: "testAvatar")!
    return TransactionCellTwitterConfig(avatar: avatar, displayHandle: "@adam_wolf")
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.directionView, "directionView should be connected")
    XCTAssertNotNil(self.sut.twitterAvatarView, "twitterAvatarView should be connected")
    XCTAssertNotNil(self.sut.counterpartyLabel, "counterpartyLabel should be connected")
    XCTAssertNotNil(self.sut.statusLabel, "statusLabel should be connected")
    XCTAssertNotNil(self.sut.dateLabel, "dateLabel should be connected")
    XCTAssertNotNil(self.sut.memoLabel, "memoLabel should be connected")
    XCTAssertNotNil(self.sut.primaryAmountLabel, "primaryAmountLabel should be connected")
    XCTAssertNotNil(self.sut.secondaryAmountLabel, "secondaryAmountLabel should be connected")
  }

  // MARK: Leading image and background color

  func testUnpaidLightningInvoice_loadsImageAndColor() {
    let viewModel = createTestViewModel(walletTxType: .lightning, direction: .in, status: .pending, isLightningTransfer: false)
    sut.configure(with: viewModel)
    let expectedImage = viewModel.lightningImage, expectedColor = UIColor.lightningBlue
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingCompletedLightning_loadsImageAndColor() {
    let viewModel = createTestViewModel(walletTxType: .lightning, direction: .in, status: .completed, isLightningTransfer: false)
    sut.configure(with: viewModel)
    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingCompletedLightning_loadsImageAndColor() {
    let viewModel = createTestViewModel(walletTxType: .lightning, direction: .out, status: .completed, isLightningTransfer: false)
    sut.configure(with: viewModel)
    let expectedImage = viewModel.outgoingImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testInvalidTransaction_loadsImageAndColor() {
    let viewModel = createTestViewModel(walletTxType: .onChain, direction: .out, isValid: false)
    sut.configure(with: viewModel)
    let expectedImage = viewModel.invalidImage, expectedColor = UIColor.invalid
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingOnChain_loadsImageAndColor() {
    let viewModel = createTestViewModel(walletTxType: .onChain, direction: .in)
    sut.configure(with: viewModel)
    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingOnChain_loadsImageAndColor() {
    let viewModel = createTestViewModel(walletTxType: .onChain, direction: .out)
    sut.configure(with: viewModel)
    let expectedImage = viewModel.outgoingImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingOnChain_LightningTransfer_loadsImageAndColor() {
    let viewModel = createTestViewModel(walletTxType: .onChain, direction: .out, isLightningTransfer: true)
    sut.configure(with: viewModel)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingOnChain_LightningTransfer_loadsImageAndColor() {
    let viewModel = createTestViewModel(walletTxType: .onChain, direction: .in, isLightningTransfer: true)
    sut.configure(with: viewModel)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingLightning_LightningTransfer_loadsImageAndColor() {
    let viewModel = createTestViewModel(walletTxType: .lightning, direction: .out, isLightningTransfer: true)
    sut.configure(with: viewModel)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingLightning_LightningTransfer_loadsImageAndColor() {
    let viewModel = createTestViewModel(walletTxType: .lightning, direction: .in, isLightningTransfer: true)
    sut.configure(with: viewModel)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testTwitterConfig_showsHidesLeadingViews() {
    let twitterConfig = createTestTwitterConfig()
    let viewModel = createTestViewModel(twitterConfig: twitterConfig)
    sut.configure(with: viewModel)
    XCTAssertFalse(sut.twitterAvatarView.isHidden)
    XCTAssertTrue(sut.directionView.isHidden)
  }

  func testNilTwitterConfig_showsHidesLeadingViews() {
    let viewModel = createTestViewModel()
    sut.configure(with: viewModel)
    XCTAssertTrue(sut.twitterAvatarView.isHidden)
    XCTAssertFalse(sut.directionView.isHidden)
  }

  // MARK: Labels

  func testMemoIsLoadedAndShown() {
    let expectedMemo = "Concert tickets"
    let viewModel = createTestViewModel(memo: expectedMemo)
    sut.configure(with: viewModel)
    XCTAssertFalse(sut.memoLabel.isHidden)
    XCTAssertEqual(sut.memoLabel.text, expectedMemo)
  }

}
