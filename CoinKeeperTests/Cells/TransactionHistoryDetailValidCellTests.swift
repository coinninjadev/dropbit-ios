//
//  TransactionHistoryDetailValidCellTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 4/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

//swiftlint:disable weak_delegate
//swiftlint:disable file_length
//swiftlint:disable type_body_length

/// Includes tests for properties and functions defined in both the ValidCell and BaseCell.
class TransactionHistoryDetailValidCellTests: XCTestCase {
  var sut: TransactionHistoryDetailValidCell!
  var mockDelegate: MockTransactionHistoryDetailCellDelegate!

  override func setUp() {
    super.setUp()
    self.sut = TransactionHistoryDetailValidCell.nib().instantiate(withOwner: self, options: nil).first as? TransactionHistoryDetailValidCell
    self.sut.awakeFromNib()
    mockDelegate = MockTransactionHistoryDetailCellDelegate()
    self.sut.delegate = mockDelegate
  }

  override func tearDown() {
    mockDelegate = nil
    sut = nil
    super.tearDown()
  }

  // MARK: - Outlets & Actions

  // MARK: Outlets connected
  func testBaseCellOutletsAreConnected() {
    XCTAssertNotNil(sut.underlyingContentView, "underlyingContentView should be connected")
    XCTAssertNotNil(sut.twitterShareButton, "twitterShareButton should be connected")
    XCTAssertNotNil(sut.questionMarkButton, "questionMarkButton should be connected")
    XCTAssertNotNil(sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(sut.directionView, "directionView should be connected")
    XCTAssertNotNil(sut.statusLabel, "statusLabel should be connected")
    XCTAssertNotNil(sut.twitterAvatarView, "twitterAvatarView should be connected")
    XCTAssertNotNil(sut.counterpartyLabel, "counterpartyLabel should be connected")
    XCTAssertNotNil(sut.primaryAmountLabel, "primaryAmountLabel should be connected")
    XCTAssertNotNil(sut.secondaryAmountLabel, "secondaryAmountLabel should be connected")
    XCTAssertNotNil(sut.historicalValuesLabel, "historicalValuesLabel should be connected")
    XCTAssertNotNil(sut.addMemoButton, "addMemoButton should be connected")
    XCTAssertNotNil(sut.memoContainerView, "memoContainerView should be connected")
    XCTAssertNotNil(sut.dateLabel, "dateLabel should be connected")
  }

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

  // MARK: Buttons contain actions
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
    XCTAssertTrue(mockDelegate.tappedClose)
  }

  func testQuestionMarkButtonTellsDelegate() {
    let twitter = MockDetailCellVM.mockTwitterConfig()
    let counterparty = TransactionCellCounterpartyConfig(twitterConfig: twitter)
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .out, counterpartyConfig: counterparty)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedTooltip = DetailCellTooltip.dropBit

    sut.questionMarkButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockDelegate.tappedQuestionMark)
    XCTAssertEqual(mockDelegate.receivedTooltip, expectedTooltip)
  }

  func testAddMemoButtonTellsDelegate() {
    sut.addMemoButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockDelegate.tappedAddMemo)
  }

  func testBottomButtonTellsDelegate() {
    let viewModel = MockDetailCellVM.testDetailInstance(direction: .out, invitationStatus: .requestSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedAction = TransactionDetailAction.cancelInvitation
    sut.didTapBottomButton(sut.bottomButton)
    XCTAssertTrue(mockDelegate.tappedBottomButton)
    XCTAssertEqual(mockDelegate.receivedAction, expectedAction)
  }

  // MARK: - Base Cell Configuration

  // MARK: Direction view
  func testUnpaidLightningInvoice_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .in, status: .pending, isLightningTransfer: false)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.lightningImage, expectedColor = UIColor.lightningBlue
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingCompletedLightning_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .in, status: .completed, isLightningTransfer: false)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingCompletedLightning_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .out, status: .completed, isLightningTransfer: false)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.outgoingImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testInvalidTransaction_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .out, status: .expired)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.invalidImage, expectedColor = UIColor.invalid
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingOnChain_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .in)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingOnChain_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .out)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.outgoingImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingOnChain_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .out, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingOnChain_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .in, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingLightning_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .out, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingLightning_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .in, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingPendingLightning_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .in,
                                                        status: .pending, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.transferImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  // MARK: Status label

  func testStatusLabel_broadcasting() {
    let viewModel = MockDetailCellVM.testDetailInstance(status: .broadcasting)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .broadcasting))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_pending() {
    let viewModel = MockDetailCellVM.testDetailInstance(status: .pending)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .pending))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_complete() {
    let viewModel = MockDetailCellVM.testDetailInstance(status: .completed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .complete))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_onChainDropBitSent() {
    let counterparty = TransactionCellCounterpartyConfig(displayName: nil,
                                                         displayPhoneNumber: nil,
                                                         twitterConfig: MockDetailCellVM.mockTwitterConfig())
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .out,
                                                        status: .pending, counterpartyConfig: counterparty)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .dropBitSent))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_lightningDropBitSent() {
    let counterparty = TransactionCellCounterpartyConfig(displayName: nil,
                                                         displayPhoneNumber: nil,
                                                         twitterConfig: MockDetailCellVM.mockTwitterConfig())
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .out,
                                                        status: .pending, counterpartyConfig: counterparty)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .dropBitSentInvitePending))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_pendingOnChainDropBitReceived() {
    let counterparty = TransactionCellCounterpartyConfig(displayName: nil,
                                                         displayPhoneNumber: nil,
                                                         twitterConfig: MockDetailCellVM.mockTwitterConfig())
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .in,
                                                        status: .pending, counterpartyConfig: counterparty)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .pending))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_dropBitCanceled() {
    let viewModel = MockDetailCellVM.testDetailInstance(status: .canceled)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .dropBitCanceled))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.warningText)
  }

  func testStatusLabel_transactionExpired() {
    let viewModel = MockDetailCellVM.testDetailInstance(status: .expired)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .transactionExpired))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.warningText)
  }

  func testStatusLabel_broadcastFailed() {
    let viewModel = MockDetailCellVM.testDetailInstance(status: .failed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .broadcastFailed))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.warningText)
  }

  func testStatusLabel_invoicePaid() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, status: .completed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .invoicePaid))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_withdrawFromLightning() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .out,
                                                        status: .completed, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .withdrawFromLightning))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_loadLightning() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .in,
                                                        status: .completed, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .loadLightning))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  // MARK: Twitter image
  func testTwitterConfig_loadsAvatar() {
    let twitterConfig = MockDetailCellVM.mockTwitterConfig()
    let counterpartyConfig = TransactionCellCounterpartyConfig(twitterConfig: twitterConfig)
    let expectedImage = twitterConfig.avatar
    let viewModel = MockDetailCellVM.testDetailInstance(counterpartyConfig: counterpartyConfig)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.twitterAvatarView.isHidden)
    XCTAssertFalse(sut.twitterAvatarView.avatarImageView.isHidden)
    XCTAssertFalse(sut.twitterAvatarView.twitterLogoImageView.isHidden)
    XCTAssertEqual(sut.twitterAvatarView.avatarImageView.image, expectedImage)
  }

  func testPhoneConfig_hidesAvatarView() {
    let counterpartyConfig = TransactionCellCounterpartyConfig(displayPhoneNumber: "(555) 123-4567")
    let viewModel = MockDetailCellVM.testDetailInstance(counterpartyConfig: counterpartyConfig)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.twitterAvatarView.isHidden)
    XCTAssertFalse(sut.directionView.isHidden)
  }

  func testNilCounterpartyConfig_hidesAvatarView() {
    let viewModel = MockDetailCellVM.testDetailInstance()
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.twitterAvatarView.isHidden)
  }

  // MARK: Counterparty label
  func testNilCounterpartyText_hidesCounterparyLabel() {
    let viewModel = MockDetailCellVM.testDetailInstance(counterpartyConfig: nil)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.counterpartyLabel.isHidden)
  }

  func testAddressCounterpartyText_hidesCounterpartyLabel() {
    let expectedAddress = TestHelpers.mockValidBech32Address()
    let viewModel = MockDetailCellVM.testDetailInstance(receiverAddress: expectedAddress)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.counterpartyLabel.isHidden)
    XCTAssertNotNil(sut.addressView.config)
    XCTAssertEqual(sut.addressView.addressTextButton.titleLabel?.text, expectedAddress)
  }

  func testCounterpartyText_ShowsCounterpartyLabel() {
    let counterparty = TransactionCellCounterpartyConfig(displayName: "Satoshi", displayPhoneNumber: nil, twitterConfig: nil)
    let viewModel = MockDetailCellVM.testDetailInstance(counterpartyConfig: counterparty)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.counterpartyLabel.isHidden)
    XCTAssertEqual(sut.counterpartyLabel.text, counterparty.displayName)
  }

  // MARK: Amount labels
  func testPrimaryAmountShowsFiat() {
    let amountDetails = MockDetailCellVM.testAmountDetails(cents: 1500)
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .in, amountDetails: amountDetails)
    let expectedText = "$15.00"
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.primaryAmountLabel.text, expectedText)
  }

  func testPrimaryAmountShowsNegativeWhenOutgoing() {
    let amountDetails = MockDetailCellVM.testAmountDetails(cents: 1500)
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .out, amountDetails: amountDetails)
    let expectedText = "-$15.00"
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.primaryAmountLabel.text, expectedText)
  }

  func testSecondaryAmountShowsBitcoinOnChain() {
    let amountDetails = MockDetailCellVM.testAmountDetails(sats: 875_000)
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .out,
                                                        amountDetails: amountDetails)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(viewModel.detailAmountLabels.secondaryAttributedText.hasImageAttachment())
    XCTAssertTrue(sut.secondaryAmountLabel.attributedText?.hasImageAttachment() ?? false)
  }

  func testSecondaryAmountShowsSatsForLightning() {
    let amountDetails = MockDetailCellVM.testAmountDetails(sats: 875_000)
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning, direction: .out,
                                                        amountDetails: amountDetails)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedText = "875,000 sats"
    let actualText = sut.secondaryAmountLabel.attributedText?.string
    XCTAssertFalse(viewModel.detailAmountLabels.secondaryAttributedText.hasImageAttachment())
    XCTAssertFalse(sut.secondaryAmountLabel.attributedText?.hasImageAttachment() ?? false)
    XCTAssertEqual(actualText, expectedText)
  }

  func testHistoricalIsHiddenWhenAmountIsNil() {
    let amountDetails = TransactionAmountDetails(btcAmount: .zero, fiatCurrency: .USD, exchangeRates: MockDetailCellVM.testRates,
                                                 fiatWhenInvited: nil, fiatWhenTransacted: nil)
    let viewModel = MockDetailCellVM.testDetailInstance(amountDetails: amountDetails)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.historicalValuesLabel.isHidden)
  }

  func testHistoricalIsShownAndSet() {
    let amountDetails = TransactionAmountDetails(btcAmount: .one, fiatCurrency: .USD, exchangeRates: MockDetailCellVM.testRates,
                                                 fiatWhenInvited: .one, fiatWhenTransacted: .one)
    let viewModel = MockDetailCellVM.testDetailInstance(direction: .out,
                                                        amountDetails: amountDetails,
                                                        invitationStatus: .completed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.historicalValuesLabel.isHidden)
    let expectedText = "$1.00 when sent $1.00 when received"
    let actualText = sut.historicalValuesLabel.attributedText?.string
    XCTAssertEqual(actualText, expectedText)
  }

  // MARK: Memo view
  func testMemoView_nilMemoHidesView() {
    let viewModel = MockDetailCellVM.testDetailInstance(memo: nil)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.memoContainerView.isHidden)
  }

  func testMemoView_emptyMemoPopulatesAndHidesView() {
    let expectedMemo = ""
    let viewModel = MockDetailCellVM.testDetailInstance(memo: expectedMemo)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.memoContainerView.memoLabel.text, expectedMemo)
    XCTAssertTrue(sut.memoContainerView.isHidden)
  }

  func testMemoView_memoPopulatesMemoView() {
    let viewModel = MockDetailCellVM.testDetailInstance(memo: "My memo")
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.memoContainerView.isHidden)
    XCTAssertEqual(sut.memoContainerView.memoLabel.text, viewModel.memo)
  }

  func testMemoView_lightningTransferMemoIsHiddenIfPresent() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning,
                                                        isLightningTransfer: true,
                                                        memo: "lightning withdrawal for 10,000 sats")
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.memoContainerView.isHidden)
  }

  func testAddMemoButton_isShownIfMemoIsNil() {
    let viewModel = MockDetailCellVM.testDetailInstance(memo: nil)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.addMemoButton.isHidden)
  }

  func testAddMemoButton_isHiddenIfMemoExists() {
    let viewModel = MockDetailCellVM.testDetailInstance(memo: "My memo")
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.addMemoButton.isHidden)
  }

  func testAddMemoButton_isHiddenIfLightningTransfer() {
    let viewModel = MockDetailCellVM.testDetailInstance(isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.addMemoButton.isHidden)
  }

  func testDateLabelShowsDate() {
    let now = Date()
    let expectedDisplayDate = CKDateFormatter.displayFull.string(from: now)
    let viewModel = MockDetailCellVM.testDetailInstance(date: now)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.dateLabel.text, expectedDisplayDate)
  }

  // MARK: - Valid Cell Configuration

  // MARK: Message label
  func testMessageLabel_nilMessageHidesLabel() {
    let viewModel = MockDetailCellVM.testDetailInstance()
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.messageLabel.isHidden)
    XCTAssertTrue(sut.messageContainer.isHidden)
  }

  func testMessageLabel_addressSentShowsLabel() {
    let counterparty = TransactionCellCounterpartyConfig(displayName: "Satoshi")
    let viewModel = MockDetailCellVM.testDetailInstance(counterpartyConfig: counterparty, invitationStatus: .addressSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.messageLabel.isHidden)
    XCTAssertFalse(sut.messageContainer.isHidden)
  }

  // MARK: Progress view
  func testProgressView_hideIfLightning() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .lightning)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.progressView.isHidden)
  }

  func testProgressView_hideIfCompleted() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, status: .completed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.progressView.isHidden)
  }

  func testProgressView_hideIfFailed() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, status: .failed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.progressView.isHidden)
  }

  func testProgressView_hideIfExpired() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, status: .expired)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.progressView.isHidden)
  }

  func testProgressView_hideIfCanceled() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, status: .canceled)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.progressView.isHidden)
  }

  func testProgressView_pendingInvitationShows5Steps() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, status: .pending, invitationStatus: .requestSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.progressView.isHidden)
    XCTAssertEqual(sut.progressView.stepTitles.count, 5)
    XCTAssertEqual(sut.progressBarWidthConstraint.constant, 250)
  }

  func testProgressView_pendingOnChainSendShows3Steps() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, status: .pending)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.progressView.isHidden)
    XCTAssertEqual(sut.progressView.stepTitles.count, 3)
    XCTAssertEqual(sut.progressBarWidthConstraint.constant, 130)
  }

  func testProgressView_pendingTransactionSelectsSecondStep() {
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, status: .pending, onChainConfirmations: 0)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.progressView.isHidden)
    XCTAssertEqual(sut.progressView.stepTitles.count, 3)
    XCTAssertEqual(sut.progressView.currentTab, 2)
    XCTAssertEqual(sut.progressBarWidthConstraint.constant, 130)
  }

  // MARK: Address view
  func testAddressViewDelegateIsSet() {
    let viewModel = MockDetailCellVM.testDetailInstance()
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertNotNil(sut.addressView.selectionDelegate)
  }

  func testAddressViewIsConfigured() {
    let viewModel = MockDetailCellVM.testDetailInstance()
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertNotNil(sut.addressView.config)
  }

  func testLightningTransferHidesAddressView() {
    let viewModel = MockDetailCellVM.testDetailInstance(isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.addressView.isHidden)
  }

  // MARK: Bottom button
  func testButtonTitleIsSet() {
    let viewModel = MockDetailCellVM.testDetailInstance(direction: .out, invitationStatus: .requestSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedTitle = TransactionDetailAction.cancelInvitation.buttonTitle
    XCTAssertEqual(sut.bottomButton.titleLabel?.text, expectedTitle)
    XCTAssertFalse(sut.bottomButton.isHidden)
  }

  func testButtonColorIsSet() {
    let viewModel = MockDetailCellVM.testDetailInstance(direction: .out, invitationStatus: .requestSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedColor = UIColor.darkPeach
    XCTAssertEqual(sut.bottomButton.backgroundColor, expectedColor)
  }

  func testCanceledDropBitHidesButton() {
    let viewModel = MockDetailCellVM.testDetailInstance(direction: .out,
                                                        invitationStatus: .canceled)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.bottomButton.isHidden)
  }

  func testCancelActionSetsButtonTag() {
    let viewModel = MockDetailCellVM.testDetailInstance(direction: .out, invitationStatus: .requestSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedAction = TransactionDetailAction.cancelInvitation
    let buttonTag = sut.bottomButton.tag
    let actualAction = TransactionDetailAction(rawValue: buttonTag)
    XCTAssertEqual(actualAction, expectedAction)
  }

  // MARK: Tooltip
  func testTooltipTypeSetsButtonTag() {
    let twitter = MockDetailCellVM.mockTwitterConfig()
    let counterparty = TransactionCellCounterpartyConfig(twitterConfig: twitter)
    let viewModel = MockDetailCellVM.testDetailInstance(walletTxType: .onChain, direction: .out, counterpartyConfig: counterparty)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedTooltip = DetailCellTooltip.dropBit
    let buttonTag = sut.questionMarkButton.tag
    let actualTooltip = DetailCellTooltip(rawValue: buttonTag)
    XCTAssertEqual(actualTooltip, expectedTooltip)
  }

}
