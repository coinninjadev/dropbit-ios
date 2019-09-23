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
    XCTAssertNotNil(sut.directionView, "directionView should be connected")
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
    sut.didTapBottomButton(sut.bottomButton)
    XCTAssertTrue(mockCoordinator.tappedBottomButton)
  }

  func testUnpaidLightningInvoice_loadsImageAndColor() {
    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .lightning, direction: .in, status: .pending, isLightningTransfer: false)
    sut.configure(with: viewModel)
    let expectedImage = viewModel.lightningImage, expectedColor = UIColor.lightningBlue
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

//  func testIncomingCompletedLightning_loadsImageAndColor() {
//    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .lightning, direction: .in, status: .completed, isLightningTransfer: false)
//    sut.configure(with: viewModel)
//    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
//    XCTAssertEqual(sut.directionView.image, expectedImage)
//    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
//  }
//
//  func testOutgoingCompletedLightning_loadsImageAndColor() {
//    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .lightning, direction: .out, status: .completed, isLightningTransfer: false)
//    sut.configure(with: viewModel)
//    let expectedImage = viewModel.outgoingImage, expectedColor = UIColor.outgoingGray
//    XCTAssertEqual(sut.directionView.image, expectedImage)
//    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
//  }
//
//  func testInvalidTransaction_loadsImageAndColor() {
//    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .onChain, direction: .out, status: .expired)
//    sut.configure(with: viewModel)
//    let expectedImage = viewModel.invalidImage, expectedColor = UIColor.invalid
//    XCTAssertEqual(sut.directionView.image, expectedImage)
//    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
//  }
//
//  func testIncomingOnChain_loadsImageAndColor() {
//    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .onChain, direction: .in)
//    sut.configure(with: viewModel)
//    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
//    XCTAssertEqual(sut.directionView.image, expectedImage)
//    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
//  }
//
//  func testOutgoingOnChain_loadsImageAndColor() {
//    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .onChain, direction: .out)
//    sut.configure(with: viewModel)
//    let expectedImage = viewModel.outgoingImage, expectedColor = UIColor.outgoingGray
//    XCTAssertEqual(sut.directionView.image, expectedImage)
//    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
//  }
//
//  func testOutgoingOnChain_LightningTransfer_loadsImageAndColor() {
//    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .onChain, direction: .out, isLightningTransfer: true)
//    sut.configure(with: viewModel)
//    let expectedImage = viewModel.transferImage, expectedColor = UIColor.outgoingGray
//    XCTAssertEqual(sut.directionView.image, expectedImage)
//    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
//  }
//
//  func testIncomingOnChain_LightningTransfer_loadsImageAndColor() {
//    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .onChain, direction: .in, isLightningTransfer: true)
//    sut.configure(with: viewModel)
//    let expectedImage = viewModel.transferImage, expectedColor = UIColor.incomingGreen
//    XCTAssertEqual(sut.directionView.image, expectedImage)
//    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
//  }
//
//  func testOutgoingLightning_LightningTransfer_loadsImageAndColor() {
//    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .lightning, direction: .out, isLightningTransfer: true)
//    sut.configure(with: viewModel)
//    let expectedImage = viewModel.transferImage, expectedColor = UIColor.outgoingGray
//    XCTAssertEqual(sut.directionView.image, expectedImage)
//    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
//  }
//
//  func testIncomingLightning_LightningTransfer_loadsImageAndColor() {
//    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .lightning, direction: .in, isLightningTransfer: true)
//    sut.configure(with: viewModel)
//    let expectedImage = viewModel.transferImage, expectedColor = UIColor.incomingGreen
//    XCTAssertEqual(sut.directionView.image, expectedImage)
//    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
//  }
//
//  func testIncomingPendingLightning_LightningTransfer_loadsImageAndColor() {
//    let viewModel = MockSummaryCellVM.testInstance(walletTxType: .lightning, direction: .in,
//                                                   status: .pending, isLightningTransfer: true)
//    sut.configure(with: viewModel)
//    let expectedImage = viewModel.transferImage, expectedColor = UIColor.incomingGreen
//    XCTAssertEqual(sut.directionView.image, expectedImage)
//    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
//  }


}
