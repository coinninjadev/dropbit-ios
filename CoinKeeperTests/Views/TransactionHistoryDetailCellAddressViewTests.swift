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

  // MARK: Show/hide address views

  private var mockAddress: String {
    return TestHelpers.mockValidBech32Address()
  }

  func testReceiverAddressShowsAddressButton() {
    let config = MockAddressViewConfig(receiverAddress: TestHelpers.mockValidBech32Address(),
                                       addressProvidedToSender: nil,
                                       broadcastFailed: false,
                                       invitationStatus: nil)

    sut.configure(with: config)
    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be hidden")
    XCTAssertFalse(self.sut.addressContainerView.isHidden, "addressContainerView should be visible")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), config.receiverAddress)
  }

  func testInvitationOutgoingTransactionShowsInvitationStatus() {
    let config = MockAddressViewConfig(receiverAddress: nil,
                                       addressProvidedToSender: nil,
                                       broadcastFailed: false,
                                       invitationStatus: .requestSent)

    sut.configure(with: config)
    XCTAssertFalse(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be visible")
    XCTAssertTrue(self.sut.addressContainerView.isHidden, "addressContainerView should be hidden")
    XCTAssertEqual(self.sut.addressStatusLabel.text, "Waiting on Bitcoin address")
  }

  func testTemporaryOutgoingTransactionShowsAddressButton() {
    let config = MockAddressViewConfig(receiverAddress: mockAddress,
                                       addressProvidedToSender: nil,
                                       broadcastFailed: false,
                                       invitationStatus: nil)
    sut.configure(with: config)
    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be hidden")
    XCTAssertFalse(self.sut.addressContainerView.isHidden, "addressContainerView should be visible")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), mockAddress, "addressTextButton title should equal destination address")
  }

  func testCompletedDropBitShowsAddressContainerView() {
    let config = MockAddressViewConfig(receiverAddress: mockAddress,
                                       addressProvidedToSender: nil,
                                       broadcastFailed: false,
                                       invitationStatus: .completed)
    sut.configure(with: config)
    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be hidden")
    XCTAssertFalse(self.sut.addressContainerView.isHidden, "addressContainerView should be visible")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), mockAddress, "addressTextButton title should equal destination address")
  }

  private func dropBitAddressViewConfig(status: InvitationStatus,
                                        receiverAddress: String?,
                                        addressForSender: String? = nil) -> MockAddressViewConfig {
    return MockAddressViewConfig(receiverAddress: receiverAddress,
                                 addressProvidedToSender: addressForSender,
                                 broadcastFailed: false,
                                 invitationStatus: status)
  }

  func testUnfulfilledDropBitHidesAddressContainerView() {

    let notSentConfig = dropBitAddressViewConfig(status: .notSent, receiverAddress: nil)
    sut.configure(with: notSentConfig)

    XCTAssertTrue(self.sut.addressContainerView.isHidden, "addressContainerView should be hidden")
    XCTAssertFalse(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be visible")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), nil, "addressTextButton title should be nil")

    let requestSentConfig = dropBitAddressViewConfig(status: .requestSent, receiverAddress: nil)
    sut.configure(with: requestSentConfig)

    XCTAssertTrue(self.sut.addressContainerView.isHidden, "addressContainerView should be hidden")
    XCTAssertFalse(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be visible")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), nil, "addressTextButton title should be nil")

    let addressSentConfig = dropBitAddressViewConfig(status: .addressProvided,
                                                     receiverAddress: mockAddress,
                                                     addressForSender: mockAddress)
    sut.configure(with: addressSentConfig)

    XCTAssertFalse(self.sut.addressContainerView.isHidden, "addressContainerView should be hidden")
    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be visible")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), mockAddress, "addressTextButton title should equal destination address")

    let canceledConfig = dropBitAddressViewConfig(status: .canceled, receiverAddress: nil)
    sut.configure(with: canceledConfig)

    XCTAssertTrue(self.sut.addressContainerView.isHidden, "addressContainerView should be hidden")
    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be hidden")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), nil, "addressTextButton title should be nil")

    let expiredConfig = dropBitAddressViewConfig(status: .expired, receiverAddress: nil)
    sut.configure(with: expiredConfig)

    XCTAssertTrue(self.sut.addressContainerView.isHidden, "addressContainerView should be hidden")
    XCTAssertTrue(self.sut.addressStatusLabel.isHidden, "addressStatusLabel should be hidden")
    XCTAssertEqual(self.sut.addressTextButton.title(for: .normal), nil, "addressTextButton title should be nil")
  }

}
