//
//  TransactionHistoryDetailCellAddressViewTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 6/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class TransactionHistoryDetailCellAddressViewTests: XCTestCase {
  var sut: TransactionHistoryDetailCellAddressView!

  override func setUp() {
    super.setUp()
    let frame = CGRect(x: 0, y: 0, width: 375, height: 80)
    self.sut = TransactionHistoryDetailCellAddressView(frame: frame)
    _ = self.sut.xibSetup()
    self.sut.awakeFromNib()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  private var testPayloadDTO: SharedPayloadDTO {
    return SharedPayloadDTO(addressPubKeyState: .none, walletTxType: .onChain, sharingDesired: false, memo: "test memo", amountInfo: nil)
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.addressTextButton, "addressTextButton should be connected")
    XCTAssertNotNil(self.sut.addressImageButton, "addressImageButton should be connected")
    XCTAssertNotNil(self.sut.addressStatusLabel, "addressStatusLabel should be connected")
    XCTAssertNotNil(self.sut.addressContainerView, "addressContainerView should be connected")
  }

  // MARK: initial state
  func testViewInitialState() {
    XCTAssertEqual(self.sut.backgroundColor, .clear)
    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should initially be hidden")
    XCTAssertFalse(self.sut.addressContainerView.isHidden, "addressContainerView should initially be visible")
  }

  // MARK: buttons contain actions
  func testBothAddressButtonsContainSameAction() {
    let textActions = self.sut.addressTextButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let imageActions = self.sut.addressImageButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let expectedActionDescription = #selector(TransactionHistoryDetailCellAddressView.addressButtonTapped(_:)).description

    XCTAssertTrue(textActions.contains(expectedActionDescription), "addressTextButton actions should contain expected action")
    XCTAssertTrue(imageActions.contains(expectedActionDescription), "addressTextButton actions should contain expected action")
  }

  // MARK: actions produce results
  func testTappingAddressButtonTellsDelegateWithAddress() {
    let mockDelegate = MockTxHistoryDetailAddressViewDelegate()
    self.sut.selectionDelegate = mockDelegate
    let expectedText = TestHelpers.mockValidBitcoinAddress()
    self.sut.addressTextButton.setTitle(expectedText, for: .normal)

    self.sut.addressTextButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockDelegate.addressViewDidSelectAddressWasCalled, "should tell delegate that button was tapped")
  }

  //TODO: revise tests
  // MARK: loading with view model produces desired UI behavior
  /*
  func testRegularIncomingTransactionShowsAddressButton() {
    let sampleCounterpartyAddress = SampleCounterpartyAddress(addressId: "13r1jyivitShUiv9FJvjLH7Nh1ZZptumwE")
    let sampleTransaction = SampleTransaction(
      netWalletAmount: nil,
      id: "",
      btcReceived: 1,
      isIncoming: true,
      walletAddress: SampleTransaction.sampleWalletAddress,
      confirmations: 1,
      date: Date(),
      counterpartyAddress: sampleCounterpartyAddress,
      phoneNumber: nil,
      invitation: nil
    )

    self.sut.load(with: sampleTransaction)

    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be hidden")
    XCTAssertFalse(self.sut.addressContainerView.isHidden, "addressContainerView should be visible")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), sampleTransaction.walletAddress)
  }

  func testRegularOutgoingTransactionShowsAddressButton() {
    let validAddress = TestHelpers.mockValidBitcoinAddress()
    let sampleCounterpartyAddress = SampleCounterpartyAddress(addressId: validAddress)
    let sampleTransaction = SampleTransaction(
      netWalletAmount: nil,
      id: "",
      btcReceived: 1,
      isIncoming: false,
      walletAddress: SampleTransaction.sampleWalletAddress,
      confirmations: 1,
      date: Date(),
      counterpartyAddress: sampleCounterpartyAddress,
      phoneNumber: nil,
      invitation: nil
    )

    self.sut.load(with: sampleTransaction)

    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be hidden")
    XCTAssertFalse(self.sut.addressContainerView.isHidden, "addressContainerView should be visible")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), sampleCounterpartyAddress.addressId)
  }

  func testContactOutgoingTransactionShowsCounterpartyAndAddress() {
    let validAddress = TestHelpers.mockValidBitcoinAddress()
    let sampleCounterpartyAddress = SampleCounterpartyAddress(addressId: validAddress)
    let expectedName = "Indiana Jones"
    let sampleCounterpartyName = SampleCounterpartyName(name: expectedName)
    let samplePhoneNumber = SamplePhoneNumber(
      countryCode: 1,
      number: 3305551212,
      phoneNumberHash: "",
      status: "",
      counterpartyName: sampleCounterpartyName
    )
    let sampleTransaction = SampleTransaction(
      netWalletAmount: nil,
      id: "",
      btcReceived: 1,
      isIncoming: false,
      walletAddress: SampleTransaction.sampleWalletAddress,
      confirmations: 1,
      date: Date(),
      counterpartyAddress: sampleCounterpartyAddress,
      phoneNumber: samplePhoneNumber,
      invitation: nil
    )

    self.sut.load(with: sampleTransaction)

    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be hidden")
    XCTAssertFalse(self.sut.addressContainerView.isHidden, "addressContainerView should be visible")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), sampleCounterpartyAddress.addressId)
  }

  func testInvitationOutgoingTransactionShowsInvitationStatus() {
    let sampleCounterpartyAddress = SampleCounterpartyAddress(addressId: "13r1jyivitShUiv9FJvjLH7Nh1ZZptumwE")
    let expectedName = "Indiana Jones"
    let sampleCounterpartyName = SampleCounterpartyName(name: expectedName)
    let samplePhoneNumber = SamplePhoneNumber(
      countryCode: 1,
      number: 3305551212,
      phoneNumberHash: "",
      status: "",
      counterpartyName: sampleCounterpartyName
    )
    let invitation = SampleInvitation(
      name: expectedName,
      phoneNumber: GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212"),
      btcAmount: 1,
      fees: 30,
      sentDate: Date(),
      status: InvitationStatus.requestSent
    )
    let sampleTransaction = SampleTransaction(
      netWalletAmount: nil,
      id: "",
      btcReceived: 1,
      isIncoming: false,
      walletAddress: SampleTransaction.sampleWalletAddress,
      confirmations: 1,
      date: Date(),
      counterpartyAddress: sampleCounterpartyAddress,
      phoneNumber: samplePhoneNumber,
      invitation: invitation
    )
    sampleTransaction.invitationStatus = .requestSent

    self.sut.load(with: sampleTransaction)

    XCTAssertFalse(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be visible")
    XCTAssertTrue(self.sut.addressContainerView.isHidden, "addressContainerView should be hidden")
    XCTAssertEqual(self.sut.addressStatusLabel.text, "Waiting on Bitcoin address")
  }

  func testTemporaryOutgoingTransactionShowsAddressButton() {
    // given
    let expectedAddress = "3NNE2SY73JkrupbWKu6iVCsGjrcNKXH4hR"
    let stack = InMemoryCoreDataStack()
    let indianaJones = GenericContact(phoneNumber: GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212"), formatted: "")
    let otd = OutgoingTransactionData(
      txid: "123txid",
      dropBitType: .phone(indianaJones),
      destinationAddress: expectedAddress,
      amount: 1,
      feeAmount: 1,
      sentToSelf: false,
      requiredFeeRate: nil,
      sharedPayloadDTO: testPayloadDTO)
    let transaction = CKMTransaction.findOrCreate(with: otd, in: stack.context)
    let rates: ExchangeRates = [.BTC: 1, .USD: 7000]

    let viewModel = OldTransactionDetailCellViewModel(
      transaction: transaction,
      rates: rates,
      primaryCurrency: .USD,
      deviceCountryCode: nil
    )

    // when
    self.sut.load(with: viewModel)

    // then
    XCTAssertFalse(self.sut.addressContainerView.isHidden, "addressContainerView should be visible")
    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be hidden")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), expectedAddress, "addressTextButton title should equal destination address")
  }

  func testCompletedDropBitShowsAddressContainerView() {
    // given
    let expectedAddress = "3NNE2SY73JkrupbWKu6iVCsGjrcNKXH4hR"
    let stack = InMemoryCoreDataStack()
    let globalNumber = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212")
    let indianaJones = ValidatedContact(
      kind: .registeredUser,
      displayName: "Indiana Jones",
      displayNumber: "+1 (330) 555-1212",
      globalPhoneNumber: globalNumber)
    let otd = OutgoingTransactionData(
      txid: "123txid",
      dropBitType: .phone(indianaJones),
      destinationAddress: expectedAddress,
      amount: 1,
      feeAmount: 1,
      sentToSelf: false,
      requiredFeeRate: nil,
      sharedPayloadDTO: testPayloadDTO)
    let transaction = CKMTransaction.findOrCreate(with: otd, in: stack.context)
    let invitation = CKMInvitation(insertInto: stack.context)
    transaction.invitation = invitation
    let rates: ExchangeRates = [.BTC: 1, .USD: 7000]

    var viewModel = OldTransactionDetailCellViewModel(
      transaction: transaction,
      rates: rates,
      primaryCurrency: .USD,
      deviceCountryCode: nil
    )

    // .completed
    invitation.status = .completed
    viewModel = OldTransactionDetailCellViewModel(
      transaction: transaction,
      rates: rates,
      primaryCurrency: .USD,
      deviceCountryCode: nil
    )

    // when
    self.sut.load(with: viewModel)

    // then
    XCTAssertFalse(self.sut.addressContainerView.isHidden, "addressContainerView should be visible")
    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be hidden")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), expectedAddress, "addressTextButton title should equal destination address")
  }

  func testUnfulfilledDropBitHidesAddressContainerView() {
    // given
    let expectedAddress = "3NNE2SY73JkrupbWKu6iVCsGjrcNKXH4hR"
    let stack = InMemoryCoreDataStack()
    let globalNumber = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212")
    let indianaJones = ValidatedContact(
      kind: .registeredUser,
      displayName: "Indiana Jones",
      displayNumber: "+1 (330) 555-1212",
      globalPhoneNumber: globalNumber)
    let otd = OutgoingTransactionData(
      txid: "123txid",
      dropBitType: .phone(indianaJones),
      destinationAddress: expectedAddress,
      amount: 1,
      feeAmount: 1,
      sentToSelf: false,
      requiredFeeRate: nil,
      sharedPayloadDTO: testPayloadDTO)

    let transaction = CKMTransaction.findOrCreate(with: otd, in: stack.context)
    let invitation = CKMInvitation(insertInto: stack.context)
    transaction.invitation = invitation
    let rates: ExchangeRates = [.BTC: 1, .USD: 7000]

    var viewModel = OldTransactionDetailCellViewModel(
      transaction: transaction, rates: rates,
      primaryCurrency: .USD, deviceCountryCode: nil
    )

    // .notSent
    invitation.status = .notSent
    viewModel = OldTransactionDetailCellViewModel(
      transaction: transaction, rates: rates,
      primaryCurrency: .USD, deviceCountryCode: nil
    )

    // when
    self.sut.load(with: viewModel)

    // then
    XCTAssertTrue(self.sut.addressContainerView.isHidden, "addressContainerView should be hidden")
    XCTAssertFalse(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be visible")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), expectedAddress, "addressTextButton title should equal destination address")

    // .requestSent
    invitation.status = .requestSent
    viewModel = OldTransactionDetailCellViewModel(
      transaction: transaction, rates: rates,
      primaryCurrency: .USD, deviceCountryCode: nil
    )

    // when
    self.sut.load(with: viewModel)

    // then
    XCTAssertTrue(self.sut.addressContainerView.isHidden, "addressContainerView should be hidden")
    XCTAssertFalse(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be visible")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), expectedAddress, "addressTextButton title should equal destination address")

    // .addressSent
    invitation.status = .addressSent
    viewModel = OldTransactionDetailCellViewModel(
      transaction: transaction, rates: rates,
      primaryCurrency: .USD, deviceCountryCode: nil
    )

    // when
    self.sut.load(with: viewModel)

    // then
    XCTAssertFalse(self.sut.addressContainerView.isHidden, "addressContainerView should be hidden")
    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be visible")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), expectedAddress, "addressTextButton title should equal destination address")

    // .canceled
    invitation.status = .canceled
    viewModel = OldTransactionDetailCellViewModel(
      transaction: transaction, rates: rates,
      primaryCurrency: .USD, deviceCountryCode: nil
    )

    // when
    self.sut.load(with: viewModel)

    // then
    XCTAssertTrue(self.sut.addressContainerView.isHidden, "addressContainerView should be hidden")
    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be hidden")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), expectedAddress, "addressTextButton title should equal destination address")

    // .expired
    invitation.status = .expired
    viewModel = OldTransactionDetailCellViewModel(
      transaction: transaction, rates: rates,
      primaryCurrency: .USD, deviceCountryCode: nil
    )

    // when
    self.sut.load(with: viewModel)

    // then
    XCTAssertTrue(self.sut.addressContainerView.isHidden, "addressContainerView should be hidden")
    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be hidden")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), expectedAddress, "addressTextButton title should equal destination address")
  }
*/
}
