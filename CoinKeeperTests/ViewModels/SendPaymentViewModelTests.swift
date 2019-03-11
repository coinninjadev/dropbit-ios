//
//  SendPaymentViewModelTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 12/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
import PhoneNumberKit
@testable import DropBit

class SendPaymentViewModelTests: XCTestCase {

  var sut: SendPaymentViewModel!

  override func setUp() {
    super.setUp()
    let kit = PhoneNumberKit()
    let parser = CKRecipientParser(kit: kit)
    self.sut = SendPaymentViewModel(btcAmount: .zero, primaryCurrency: .BTC, parser: parser)
  }

  override func tearDown() {
    super.tearDown()
    self.sut = nil
  }

  func testSettingRecipientUpdatesAddress() {
    let address = TestHelpers.mockValidBitcoinAddress()
    self.sut.paymentRecipient = .btcAddress(address)
    XCTAssertEqual(address, self.sut.address)

    let number = GlobalPhoneNumber(countryCode: 1, nationalNumber: "9375555555")
    self.sut.paymentRecipient = .contact(GenericContact(phoneNumber: number, hash: "", formatted: ""))
    XCTAssertNil(self.sut.address)
  }

  func testShowMemoSharingControlWhenVerified() {
    sut.sharedMemoAllowed = true
    let number = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212")
    let contact = GenericContact(phoneNumber: number, hash: "", formatted: "")
    sut.paymentRecipient = .contact(contact)
    XCTAssertTrue(sut.shouldShowSharedMemoBox, "shouldShowSharedMemoBox should be true")
    sut.paymentRecipient = .phoneNumber(contact)
    XCTAssertTrue(sut.shouldShowSharedMemoBox, "shouldShowSharedMemoBox should be true")
    sut.paymentRecipient = .btcAddress("fake address")
    XCTAssertFalse(sut.shouldShowSharedMemoBox, "shouldShowSharedMemoBox should be false")
  }

  func testHideMemoSharingControlWhenNotVerified() {
    sut.sharedMemoAllowed = false
    let number = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3305551212")
    let contact = GenericContact(phoneNumber: number, hash: "", formatted: "")
    sut.paymentRecipient = .contact(contact)
    XCTAssertFalse(sut.shouldShowSharedMemoBox, "shouldShowSharedMemoBox should be false")
    sut.paymentRecipient = .phoneNumber(contact)
    XCTAssertFalse(sut.shouldShowSharedMemoBox, "shouldShowSharedMemoBox should be false")
    sut.paymentRecipient = .btcAddress("fake address")
    XCTAssertFalse(sut.shouldShowSharedMemoBox, "shouldShowSharedMemoBox should be false")
  }
}
