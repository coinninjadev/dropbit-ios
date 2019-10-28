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
    let expected = #selector(TransactionHistoryDetailValidCell.didTapAddMemoButton(_:)).description
    XCTAssertTrue(actions.contains(expected), "button should contain action")
  }

  func testCloseButtonContainsAction() {
    let actions = sut.closeButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(TransactionHistoryDetailValidCell.didTapClose(_:)).description
    XCTAssertTrue(actions.contains(expected), "button should contain action")
  }

  func testQuestionMarkButtonContainsAction() {
    let actions = sut.questionMarkButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(TransactionHistoryDetailValidCell.didTapQuestionMarkButton(_:)).description
    XCTAssertTrue(actions.contains(expected), "button should contain action")
  }

  func testBottomButtonContainsAction() {
    let actions = sut.bottomButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(TransactionHistoryDetailValidCell.didTapBottomButton(_:)).description
    XCTAssertTrue(actions.contains(expected), "button should contain action")
  }

  // MARK: Delegate methods
  func testCloseButtonTellsDelegate() {
    sut.didTapClose(sut.closeButton)
    XCTAssertTrue(mockDelegate.tappedClose)
  }

  func testTwitterShareButtonTellsDelegate() {
    sut.twitterShareButton.flatMap { sut.didTapTwitterShare($0) }
    XCTAssertTrue(mockDelegate.tappedTwitterShare)
  }

  func testAddressButtonTellsDelegate() {
    let expectedAddress = MockDetailCellVM.mockValidBitcoinAddress()
    let counterparty = MockDetailCellVM.mockTwitterCounterparty()
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .out, status: .completed,
                                     receiverAddress: expectedAddress,
                                     counterpartyConfig: counterparty, invitationStatus: .completed)

    sut.configure(with: viewModel, delegate: mockDelegate)
    sut.addressView.addressTextButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockDelegate.tappedAddress)
  }

  func testQuestionMarkButtonTellsDelegate() {
    let counterparty = MockDetailCellVM.mockTwitterCounterparty()
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .out, counterpartyConfig: counterparty)
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
    let viewModel = MockDetailCellVM(direction: .out, invitationStatus: .requestSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedAction = TransactionDetailAction.cancelInvitation
    sut.didTapBottomButton(sut.bottomButton)
    XCTAssertTrue(mockDelegate.tappedBottomButton)
    XCTAssertEqual(mockDelegate.receivedAction, expectedAction)
  }

  // MARK: - Base Cell Configuration

  // MARK: Twitter share button
  func testTwitterButton_isLightningTransfer_Shown() {
    let viewModel = MockDetailCellVM(isLightningTransfer: false)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertNotNil(sut.twitterShareButton)
    XCTAssertFalse(sut.twitterShareButton!.isHidden)
  }

  func testTwitterButton_isLightningTransfer_Hidden() {
    let viewModel = MockDetailCellVM(isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertNotNil(sut.twitterShareButton)
    XCTAssertTrue(sut.twitterShareButton!.isHidden)
  }

  // MARK: Direction view
  func testPendingLightningDropBit_loadsImageAndColor() {
    let counterparty = MockDetailCellVM.mockTwitterCounterparty()
    let viewModel = MockDetailCellVM(walletTxType: .lightning, direction: .out, status: .pending,
                                     isLightningTransfer: false, counterpartyConfig: counterparty, invitationStatus: .requestSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.basicDirectionImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingCompletedLightning_loadsImageAndColor() {
    let viewModel = MockDetailCellVM(walletTxType: .lightning, direction: .in, status: .completed, isLightningTransfer: false)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingCompletedLightning_loadsImageAndColor() {
    let viewModel = MockDetailCellVM(walletTxType: .lightning, direction: .out, status: .completed, isLightningTransfer: false)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.outgoingImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testInvalidTransaction_loadsImageAndColor() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .out, status: .expired)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.invalidImage, expectedColor = UIColor.invalid
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingOnChain_loadsImageAndColor() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .in)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingOnChain_loadsImageAndColor() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .out)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.outgoingImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingOnChain_LightningTransfer_loadsOutgoingImageAndColor() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .out, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.outgoingImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingOnChain_LightningTransfer_loadsIncomingImageAndColor() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .in, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testOutgoingLightning_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM(walletTxType: .lightning, direction: .out, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.outgoingImage, expectedColor = UIColor.outgoingGray
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingLightning_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM(walletTxType: .lightning, direction: .in, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  func testIncomingPendingLightning_LightningTransfer_loadsImageAndColor() {
    let viewModel = MockDetailCellVM(walletTxType: .lightning, direction: .in,
                                     status: .pending, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedImage = viewModel.incomingImage, expectedColor = UIColor.incomingGreen
    XCTAssertEqual(sut.directionView.image, expectedImage)
    XCTAssertEqual(sut.directionView.backgroundColor, expectedColor)
  }

  // MARK: Status label

  func testStatusLabel_broadcasting() {
    let viewModel = MockDetailCellVM(status: .broadcasting)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .broadcasting))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_pending() {
    let viewModel = MockDetailCellVM(status: .pending)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .pending))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_complete() {
    let viewModel = MockDetailCellVM(status: .completed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .complete))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_onChainDropBitSent() {
    let counterparty = MockDetailCellVM.mockTwitterCounterparty()
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .out,
                                     status: .pending, counterpartyConfig: counterparty)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .dropBitSent))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_lightningDropBitSent() {
    let counterparty = MockDetailCellVM.mockTwitterCounterparty()
    let viewModel = MockDetailCellVM(walletTxType: .lightning, direction: .out,
                                     status: .pending, counterpartyConfig: counterparty)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .dropBitSentInvitePending))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_pendingOnChainDropBitReceived() {
    let counterparty = MockDetailCellVM.mockTwitterCounterparty()
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .in,
                                     status: .pending, counterpartyConfig: counterparty)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .pending))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_lightningDropBitComplete() {
    let counterparty = MockDetailCellVM.mockTwitterCounterparty()
    let viewModel = MockDetailCellVM(walletTxType: .lightning, status: .completed,
                                     counterpartyConfig: counterparty, invitationStatus: .completed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .complete))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_dropBitCanceled() {
    let viewModel = MockDetailCellVM(status: .canceled)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .dropBitCanceled))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.warning)
  }

  func testStatusLabel_transactionExpired() {
    let viewModel = MockDetailCellVM(status: .expired)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .transactionExpired))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.warning)
  }

  func testStatusLabel_broadcastFailed() {
    let viewModel = MockDetailCellVM(status: .failed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .broadcastFailed))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.warning)
  }

  func testStatusLabel_invoicePaid() {
    let viewModel = MockDetailCellVM(walletTxType: .lightning, status: .completed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .invoicePaid))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_withdrawFromLightning() {
    let viewModel = MockDetailCellVM(walletTxType: .lightning, direction: .out,
                                     status: .completed, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .withdrawFromLightning))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  func testStatusLabel_loadLightning() {
    let viewModel = MockDetailCellVM(walletTxType: .lightning, direction: .in,
                                     status: .completed, isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.statusLabel.text, viewModel.string(for: .loadLightning))
    XCTAssertEqual(sut.statusLabel.textColor, UIColor.darkGrayText)
  }

  // MARK: Twitter image
  func testTwitterConfig_loadsAvatar() {
    let counterpartyConfig = MockDetailCellVM.mockTwitterCounterparty()
    let expectedImage = counterpartyConfig.twitterConfig?.avatar
    let viewModel = MockDetailCellVM(counterpartyConfig: counterpartyConfig)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.twitterAvatarView.isHidden)
    XCTAssertFalse(sut.twitterAvatarView.avatarImageView.isHidden)
    XCTAssertFalse(sut.twitterAvatarView.twitterLogoImageView.isHidden)
    XCTAssertEqual(sut.twitterAvatarView.avatarImageView.image, expectedImage)
  }

  func testPhoneConfig_hidesAvatarView() {
    let counterpartyConfig = TransactionCellCounterpartyConfig(displayPhoneNumber: "(555) 123-4567")
    let viewModel = MockDetailCellVM(counterpartyConfig: counterpartyConfig)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.twitterAvatarView.isHidden)
    XCTAssertFalse(sut.directionView.isHidden)
  }

  func testNilCounterpartyConfig_hidesAvatarView() {
    let viewModel = MockDetailCellVM()
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.twitterAvatarView.isHidden)
  }

  // MARK: Counterparty label
  func testNilCounterpartyText_hidesCounterparyLabel() {
    let viewModel = MockDetailCellVM(counterpartyConfig: nil)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.counterpartyLabel.isHidden)
  }

  func testAddressCounterpartyText_hidesCounterpartyLabel() {
    let expectedAddress = TestHelpers.mockValidBech32Address()
    let viewModel = MockDetailCellVM(receiverAddress: expectedAddress)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.counterpartyLabel.isHidden)
    XCTAssertNotNil(sut.addressView.config)
    XCTAssertEqual(sut.addressView.addressTextButton.titleLabel?.text, expectedAddress)
  }

  func testCounterpartyText_ShowsCounterpartyLabel() {
    let counterparty = TransactionCellCounterpartyConfig(displayName: "Satoshi", displayPhoneNumber: nil, twitterConfig: nil)
    let viewModel = MockDetailCellVM(counterpartyConfig: counterparty)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.counterpartyLabel.isHidden)
    XCTAssertEqual(sut.counterpartyLabel.text, counterparty.displayName)
  }

  // MARK: Amount labels
  func testPrimaryAmountShowsFiat() {
    let amountFactory = MockDetailCellVM.testAmountFactory(cents: 1500)
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .in, amountFactory: amountFactory)
    let expectedText = "$15.00"
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.primaryAmountLabel.text, expectedText)
  }

  func testPrimaryAmountShowsNegativeWhenOutgoing() {
    let amountFactory = MockDetailCellVM.testAmountFactory(cents: 1500)
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .out, amountFactory: amountFactory)
    let expectedText = "-$15.00"
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.primaryAmountLabel.text, expectedText)
  }

  func testSecondaryAmountShowsBitcoinOnChain() {
    let amountFactory = MockDetailCellVM.testAmountFactory(sats: 875_000)
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .out,
                                     amountFactory: amountFactory)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(viewModel.detailAmountLabels.secondaryAttributedText.hasImageAttachment())
    XCTAssertTrue(sut.secondaryAmountLabel.attributedText?.hasImageAttachment() ?? false)
  }

  func testSecondaryAmountShowsSatsForLightning() {
    let amountFactory = MockDetailCellVM.testAmountFactory(sats: 875_000)
    let viewModel = MockDetailCellVM(walletTxType: .lightning, direction: .out,
                                     amountFactory: amountFactory)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedText = "875,000 sats"
    let actualText = sut.secondaryAmountLabel.attributedText?.string
    XCTAssertFalse(viewModel.detailAmountLabels.secondaryAttributedText.hasImageAttachment())
    XCTAssertFalse(sut.secondaryAmountLabel.attributedText?.hasImageAttachment() ?? false)
    XCTAssertEqual(actualText, expectedText)
  }

  func testHistoricalIsHiddenWhenAmountIsNil() {
    let amountFactory = MockDetailCellVM.testAmountFactory(sats: 0)
    let viewModel = MockDetailCellVM(amountFactory: amountFactory)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.historicalValuesLabel.isHidden)
  }

  func testHistoricalIsShownAndSet() {
    let amountFactory = MockAmountsFactory(btcAmount: .one, fiatCurrency: .USD, exchangeRates: MockDetailCellVM.testRates,
                                           fiatWhenInvited: .one, fiatWhenTransacted: .one)
    let viewModel = MockDetailCellVM(direction: .out,
                                     amountFactory: amountFactory,
                                     invitationStatus: .completed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.historicalValuesLabel.isHidden)
    let expectedText = "$1.00 when sent $1.00 when received"
    let actualText = sut.historicalValuesLabel.attributedText?.string
    XCTAssertEqual(actualText, expectedText)
  }

  func testHistoricalAmountsDoNotShowNegativeSign() {
    let historicalFiat = NSDecimalNumber(integerAmount: -100, currency: .USD)
    let amountFactory = MockAmountsFactory(btcAmount: .one, fiatCurrency: .USD, exchangeRates: MockDetailCellVM.testRates,
                                           fiatWhenInvited: historicalFiat, fiatWhenTransacted: historicalFiat)
    let viewModel = MockDetailCellVM(direction: .out,
                                     amountFactory: amountFactory,
                                     invitationStatus: .completed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.historicalValuesLabel.isHidden)
    let expectedText = "$1.00 when sent $1.00 when received"
    let actualText = sut.historicalValuesLabel.attributedText?.string
    XCTAssertEqual(actualText, expectedText)
  }

  // MARK: Memo view
  func testMemoView_nilMemoHidesView() {
    let viewModel = MockDetailCellVM(memo: nil)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.memoContainerView.isHidden)
  }

  func testMemoView_emptyMemoHidesView() {
    let expectedMemo = ""
    let viewModel = MockDetailCellVM(memo: expectedMemo)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.memoContainerView.isHidden)
  }

  func testMemoView_memoPopulatesMemoView() {
    let viewModel = MockDetailCellVM(memo: "My memo")
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.memoContainerView.isHidden)
    XCTAssertEqual(sut.memoContainerView.memoLabel.text, viewModel.memo)
  }

  func testMemoView_lightningTransferMemoIsHiddenIfPresent() {
    let viewModel = MockDetailCellVM(walletTxType: .lightning,
                                     isLightningTransfer: true,
                                     memo: "lightning withdrawal for 10,000 sats")
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.memoContainerView.isHidden)
  }

  func testAddMemoButton_isShownIfMemoIsNil() {
    let viewModel = MockDetailCellVM(memo: nil)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.addMemoButton.isHidden)
  }

  func testAddMemoButton_isHiddenIfMemoExists() {
    let viewModel = MockDetailCellVM(memo: "My memo")
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.addMemoButton.isHidden)
  }

  func testAddMemoButton_isHiddenIfLightningTransfer() {
    let viewModel = MockDetailCellVM(isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.addMemoButton.isHidden)
  }

  func testAddMemoButton_isHiddenIfIncomingNotCompleted() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .in, status: .pending, invitationStatus: .addressSent, memo: nil)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.addMemoButton.isHidden)
  }

  func testAddMemoButton_isShownIfIncomingUncomfirmedWithoutInvitation() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .in, status: .pending, memo: nil)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.addMemoButton.isHidden)
  }

  func testAddMemoButton_isShownIfOutgoingNotCompleted() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .out, status: .pending, memo: nil)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.addMemoButton.isHidden)
  }

  func testDateLabelShowsDate() {
    let now = Date()
    let expectedDisplayDate = CKDateFormatter.displayFull.string(from: now)
    let viewModel = MockDetailCellVM(date: now)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertEqual(sut.dateLabel.text, expectedDisplayDate)
  }

  // MARK: - Valid Cell Configuration

  // MARK: Message label
  func testMessageLabel_nilMessageHidesLabel() {
    let viewModel = MockDetailCellVM()
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.messageLabel.isHidden)
    XCTAssertTrue(sut.messageContainer.isHidden)
  }

  func testMessageLabel_addressSentShowsLabel() {
    let counterparty = TransactionCellCounterpartyConfig(displayName: "Satoshi")
    let viewModel = MockDetailCellVM(counterpartyConfig: counterparty, invitationStatus: .addressSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.messageLabel.isHidden)
    XCTAssertFalse(sut.messageContainer.isHidden)
  }

  // MARK: Progress view
  func testProgressView_hideIfLightning() {
    let viewModel = MockDetailCellVM(walletTxType: .lightning)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.progressView.isHidden)
  }

  func testProgressView_hideIfCompleted() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, status: .completed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.progressView.isHidden)
  }

  func testProgressView_hideIfFailed() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, status: .failed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.progressView.isHidden)
  }

  func testProgressView_hideIfExpired() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, status: .expired)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.progressView.isHidden)
  }

  func testProgressView_hideIfCanceled() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, status: .canceled)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.progressView.isHidden)
  }

  func testProgressView_pendingInvitationShows5Steps() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, status: .pending, invitationStatus: .requestSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.progressView.isHidden)
    XCTAssertEqual(sut.progressView.stepTitles.count, 5)
    XCTAssertEqual(sut.progressBarWidthConstraint.constant, 250)
  }

  func testProgressView_pendingOnChainSendShows3Steps() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, status: .pending)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.progressView.isHidden)
    XCTAssertEqual(sut.progressView.stepTitles.count, 3)
    XCTAssertEqual(sut.progressBarWidthConstraint.constant, 130)
  }

  func testProgressView_pendingTransactionSelectsSecondStep() {
    let viewModel = MockDetailCellVM(walletTxType: .onChain, status: .pending, onChainConfirmations: 0)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.progressView.isHidden)
    XCTAssertEqual(sut.progressView.stepTitles.count, 3)
    XCTAssertEqual(sut.progressView.currentTab, 2)
    XCTAssertEqual(sut.progressBarWidthConstraint.constant, 130)
  }

  // MARK: Address view
  func testAddressViewDelegateIsSet() {
    let viewModel = MockDetailCellVM()
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertNotNil(sut.addressView.selectionDelegate)
  }

  func testAddressViewIsConfigured() {
    let viewModel = MockDetailCellVM()
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertNotNil(sut.addressView.config)
  }

  func testLightningTransferHidesAddressView() {
    let viewModel = MockDetailCellVM(isLightningTransfer: true)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.addressView.isHidden)
  }

  func testIncomingPendingOnChainDropBitShowsProvidedAddress() {
    let expectedAddress = MockDetailCellVM.mockValidBitcoinAddress()
    let counterparty = MockDetailCellVM.mockTwitterCounterparty()
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .in, status: .pending,
                                     addressProvidedToSender: expectedAddress,
                                     counterpartyConfig: counterparty, invitationStatus: .addressSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.addressView.isHidden)
    XCTAssertEqual(sut.addressView.addressTextButton.titleLabel?.text, expectedAddress)
    XCTAssertFalse(sut.addressView.addressTextButton.isEnabled)
  }

  func testOutgoingCompletedOnChainDropBitShowsReceiverAddress() {
    let expectedAddress = MockDetailCellVM.mockValidBitcoinAddress()
    let counterparty = MockDetailCellVM.mockTwitterCounterparty()
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .out, status: .completed,
                                     receiverAddress: expectedAddress,
                                     counterpartyConfig: counterparty, invitationStatus: .completed)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertFalse(sut.addressView.isHidden)
    XCTAssertFalse(sut.addressView.addressTextButton.isHidden)
    XCTAssertEqual(sut.addressView.addressTextButton.titleLabel?.text, expectedAddress)
    XCTAssertTrue(sut.addressView.addressTextButton.isEnabled)
  }

  // MARK: Bottom button
  func testButtonTitleIsSet() {
    let viewModel = MockDetailCellVM(direction: .out, invitationStatus: .requestSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedTitle = TransactionDetailAction.cancelInvitation.buttonTitle
    XCTAssertEqual(sut.bottomButton.titleLabel?.text, expectedTitle)
    XCTAssertFalse(sut.bottomButton.isHidden)
  }

  func testButtonColorIsSet() {
    let viewModel = MockDetailCellVM(direction: .out, invitationStatus: .requestSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedColor = UIColor.darkPeach
    XCTAssertEqual(sut.bottomButton.backgroundColor, expectedColor)
  }

  func testCanceledDropBitHidesButton() {
    let viewModel = MockDetailCellVM(direction: .out, invitationStatus: .canceled)
    sut.configure(with: viewModel, delegate: mockDelegate)
    XCTAssertTrue(sut.bottomButton.isHidden)
  }

  func testCancelActionSetsButtonTag() {
    let viewModel = MockDetailCellVM(direction: .out, invitationStatus: .requestSent)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedAction = TransactionDetailAction.cancelInvitation
    let buttonTag = sut.bottomButton.tag
    let actualAction = TransactionDetailAction(rawValue: buttonTag)
    XCTAssertEqual(actualAction, expectedAction)
  }

  // MARK: Tooltip
  func testTooltipTypeSetsButtonTag() {
    let counterparty = MockDetailCellVM.mockTwitterCounterparty()
    let viewModel = MockDetailCellVM(walletTxType: .onChain, direction: .out, counterpartyConfig: counterparty)
    sut.configure(with: viewModel, delegate: mockDelegate)
    let expectedTooltip = DetailCellTooltip.dropBit
    let buttonTag = sut.questionMarkButton.tag
    let actualTooltip = DetailCellTooltip(rawValue: buttonTag)
    XCTAssertEqual(actualTooltip, expectedTooltip)
  }

}
