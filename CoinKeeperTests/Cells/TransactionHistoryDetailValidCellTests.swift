//
//  TransactionHistoryDetailValidCellTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 4/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

/// Includes tests for properties and functions defined in both the ValidCell and BaseCell.
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

  func testBaseCellOutletsAreConnected() {
    XCTAssertNotNil(sut.underlyingContentView, "underlyingContentView should be connected")
    XCTAssertNotNil(sut.twitterShareButton, "twitterShareButton should be connected")
    XCTAssertNotNil(sut.questionMarkButton, "questionMarkButton should be connected")
    XCTAssertNotNil(sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(sut.directionView, "directionView should be connected")
    XCTAssertNotNil(sut.statusLabel, "statusLabel should be connected")
    XCTAssertNotNil(sut.twitterImage, "twitterImage should be connected")
    XCTAssertNotNil(sut.counterpartyLabel, "counterpartyLabel should be connected")
    XCTAssertNotNil(sut.primaryAmountLabel, "primaryAmountLabel should be connected")
    XCTAssertNotNil(sut.secondaryAmountLabel, "secondaryAmountLabel should be connected")
    XCTAssertNotNil(sut.historicalValuesLabel, "historicalValuesLabel should be connected")
    XCTAssertNotNil(sut.addMemoButton, "addMemoButton should be connected")
    XCTAssertNotNil(sut.memoContainerView, "memoContainerView should be connected")
    XCTAssertNotNil(sut.dateLabel, "dateLabel should be connected")
  }

  // MARK: outlets
  func testValidCellOutletsAreConnected() {
    XCTAssertNotNil(sut.progressBarWidthConstraint, "progressBarWidthConstraint should be connected")
    XCTAssertNotNil(sut.progressView, "progressView should be connected")
    XCTAssertNotNil(sut.addressView, "addressView should be connected")
    XCTAssertNotNil(sut.bottomButton, "bottomButton should be connected")
    XCTAssertNotNil(sut.messageContainer, "messageContainer should be connected")
    XCTAssertNotNil(sut.messageLabel, "messageLabel should be connected")
    XCTAssertNotNil(sut.messageContainerHeightConstraint, "messageContainerHeightConstraint should be connected")
    XCTAssertNotNil(sut.bottomBufferView, "bottomBufferView should be connected")
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

  // MARK: Delegate methods
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
    sut.didTapBottomButton(sut.bottomButton)
    XCTAssertTrue(mockCoordinator.tappedBottomButton)
  }

  // MARK: - Direction view

  func testUnpaidLightningInvoice_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .in, status: .pending, isLightningTransfer: false)
    sut.configure(with: viewModel, delegate: mockCoordinator)
    let expectedImage = viewModel.lightningImage, expectedColor = UIColor.lightningBlue
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingCompletedLightning_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .in, status: .completed, isLightningTransfer: false)
    sut.configure(with: viewModel, delegate: mockCoordinator)
    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingCompletedLightning_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .out, status: .completed, isLightningTransfer: false)
    sut.configure(with: viewModel, delegate: mockCoordinator)
    let expectedImage = viewModel.outgoingImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testInvalidTransaction_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .out, status: .expired)
    sut.configure(with: viewModel, delegate: mockCoordinator)
    let expectedImage = viewModel.invalidImage, expectedColor = UIColor.invalid
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingOnChain_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .in)
    sut.configure(with: viewModel, delegate: mockCoordinator)
    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingOnChain_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .out)
    sut.configure(with: viewModel, delegate: mockCoordinator)
    let expectedImage = viewModel.outgoingImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingOnChain_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .out, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockCoordinator)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingOnChain_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .in, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockCoordinator)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingLightning_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .out, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockCoordinator)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingLightning_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .in, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockCoordinator)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingPendingLightning_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .in,
                                                        status: .pending, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockCoordinator)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  //TODO: migrate or delete these tests from the summary cell
  /*
  func testTwitterConfig_loadsAvatar() {
    let twitterConfig = MockSummaryCellVM.mockTwitterConfig()
    let counterpartyConfig = TransactionCellCounterpartyConfig(twitterConfig: twitterConfig)
    let expectedImage = twitterConfig.avatar
    let viewModel = MockSummaryCellVM.testInstance(counterpartyConfig: counterpartyConfig)
    sut.configure(with: viewModel)
    XCTAssertFalse(sut.twitterAvatarView.isHidden)
    XCTAssertFalse(sut.twitterAvatarView.avatarImageView.isHidden)
    XCTAssertFalse(sut.twitterAvatarView.twitterLogoImageView.isHidden)
    XCTAssertTrue(sut.directionView.isHidden)
    XCTAssertEqual(sut.twitterAvatarView.avatarImageView.image, expectedImage)
  }

  func testTwitterConfig_showsHidesLeadingViews() {
    let twitterConfig = MockSummaryCellVM.mockTwitterConfig()
    let counterpartyConfig = TransactionCellCounterpartyConfig(twitterConfig: twitterConfig)
    let viewModel = MockSummaryCellVM.testInstance(counterpartyConfig: counterpartyConfig)
    sut.configure(with: viewModel)
    XCTAssertFalse(sut.twitterAvatarView.isHidden)
    XCTAssertTrue(sut.directionView.isHidden)
  }

  func testNilTwitterConfig_showsHidesLeadingViews() {
    let viewModel = MockSummaryCellVM.testInstance()
    sut.configure(with: viewModel)
    XCTAssertTrue(sut.twitterAvatarView.isHidden)
    XCTAssertFalse(sut.directionView.isHidden)
  }

  // MARK: Labels
  func testMemoIsLoadedAndShown() {
    let expectedMemo = "Concert tickets"
    let viewModel = MockSummaryCellVM.testInstance(memo: expectedMemo)
    sut.configure(with: viewModel)
    XCTAssertFalse(sut.memoLabel.isHidden)
    XCTAssertEqual(sut.memoLabel.text, expectedMemo)
  }

  func testEmptyStringMemoIsLoadedAndHidden() {
    let expectedMemo = ""
    let viewModel = MockSummaryCellVM.testInstance(memo: expectedMemo)
    sut.configure(with: viewModel)
    XCTAssertTrue(sut.memoLabel.isHidden)
    XCTAssertEqual(sut.memoLabel.text, expectedMemo)
  }

  func testNilMemoIsLoadedAndHidden() {
    let expectedMemo: String? = nil
    let viewModel = MockSummaryCellVM.testInstance(memo: expectedMemo)
    sut.configure(with: viewModel)
    XCTAssertTrue(sut.memoLabel.isHidden)
    XCTAssertEqual(sut.memoLabel.text, expectedMemo)
  }

  func testLightningTransferMemoIsHiddenIfPresent() {
    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .lightning,
                                                   isLightningTransfer: true,
                                                   memo: "lightning withdrawal for 10,000 sats")
    sut.configure(with: viewModel)
    XCTAssertTrue(sut.memoLabel.isHidden)
  }

  func testExpiredLabelIsLoaded() {
    let expectedText = TransactionStatus.expired.rawValue, expectedColor = UIColor.invalid
    let viewModel = MockSummaryCellVM.testInstance(status: .expired)
    sut.configure(with: viewModel)
    XCTAssertEqual(sut.pillLabels.count, 1)
    XCTAssertEqual(sut.pillLabel?.text, expectedText)
    XCTAssertEqual(sut.pillLabel?.backgroundColor, expectedColor)
  }

  func testCanceledLabelIsLoaded() {
    let expectedText = TransactionStatus.canceled.rawValue, expectedColor = UIColor.invalid
    let viewModel = MockSummaryCellVM.testInstance(status: .canceled)
    sut.configure(with: viewModel)
    XCTAssertEqual(sut.pillLabels.count, 1)
    XCTAssertEqual(sut.pillLabel?.text, expectedText)
    XCTAssertEqual(sut.pillLabel?.backgroundColor, expectedColor)
  }

  func testSatsLabelIsLoadedForInvalidTransaction() {
    let amountDetails = MockSummaryCellVM.testAmountDetails(sats: 1234567)
    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .lightning, status: .canceled, amountDetails: amountDetails)
    let expectedText = "1,234,567 sats"
    sut.configure(with: viewModel)
    XCTAssertEqual(sut.satsLabels.count, 1)
    XCTAssertEqual(sut.satsLabel?.text, expectedText)
  }

  func testBTCLabelIsLoaded() {
    let amountDetails = MockSummaryCellVM.testAmountDetails(sats: 1234560)
    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .onChain, status: .canceled, amountDetails: amountDetails)
    let expectedText = BitcoinFormatter(symbolType: .attributed).attributedString(from: amountDetails.btcAmount)
    sut.configure(with: viewModel)
    XCTAssertEqual(sut.bitcoinLabels.count, 1)
    XCTAssertEqual(sut.satsLabels.count, 0)
    XCTAssertEqual(sut.bitcoinLabel?.attributedText?.string, expectedText?.string)
    XCTAssertTrue(sut.bitcoinLabel?.attributedText?.hasImageAttachment() ?? false)
  }

  func testFiatLabelIsLoaded() {
    let amountDetails = MockSummaryCellVM.testAmountDetails(sats: 1234560)
    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .onChain, direction: .in, status: .completed, amountDetails: amountDetails)
    let expectedText = viewModel.summaryAmountLabels.pillText, expectedColor = UIColor.incomingGreen
    sut.configure(with: viewModel)
    XCTAssertEqual(sut.pillLabels.count, 1)
    XCTAssertEqual(sut.pillLabel?.text, expectedText)
    XCTAssertEqual(sut.pillLabel?.backgroundColor, expectedColor)
  }

  func testFiatIsOnTopWhenSelected() {
    let viewModel = MockSummaryCellVM.testInstance(selectedCurrency: .fiat)
    sut.configure(with: viewModel)
    let firstLabelIsFiat = sut.amountStackView.arrangedSubviews.first is SummaryCellPillLabel
    XCTAssertTrue(firstLabelIsFiat)
  }

  func testBitcoinIsOnTopWhenBitcoinIsSelected() {
    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .onChain, selectedCurrency: .BTC)
    sut.configure(with: viewModel)
    let firstViewAsPaddedLabel = sut.amountStackView.arrangedSubviews.first.flatMap { $0 as? SummaryCellPaddedLabelView }
    XCTAssertNotNil(firstViewAsPaddedLabel, "first arrangedSubview should be SummaryCellPaddedLabelView")
    let subviewAsBitcoinLabel = firstViewAsPaddedLabel?.subviews.first.flatMap { $0 as? SummaryCellBitcoinLabel }
    XCTAssertNotNil(subviewAsBitcoinLabel, "subview should be SummaryCellBitcoinLabel")
  }

  func testSatsIsOnTopWhenBitcoinIsSelected() {
    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .lightning, selectedCurrency: .BTC)
    sut.configure(with: viewModel)
    let firstViewAsPaddedLabel = sut.amountStackView.arrangedSubviews.first.flatMap { $0 as? SummaryCellPaddedLabelView }
    XCTAssertNotNil(firstViewAsPaddedLabel, "first arrangedSubview should be SummaryCellPaddedLabelView")
    let subviewAsBitcoinLabel = firstViewAsPaddedLabel?.subviews.first.flatMap { $0 as? SummaryCellSatsLabel }
    XCTAssertNotNil(subviewAsBitcoinLabel, "subview should be SummaryCellSatsLabel")
  }
 */

}
