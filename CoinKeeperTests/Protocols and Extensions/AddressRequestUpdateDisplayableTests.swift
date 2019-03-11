//
//  AddressRequestUpdateDisplayableTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 7/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation
import XCTest

/// Used for testing the protocol
struct AddressRequestUpdateTestObject: AddressRequestUpdateDisplayable {
  var addressRequestId: String = UUID().uuidString
  var senderName: String?
  var senderPhoneNumber: GlobalPhoneNumber?
  var receiverName: String?
  var receiverPhoneNumber: GlobalPhoneNumber?
  var btcAmount: Int = 0
  var fiatAmount: Int = 0
  var side: InvitationSide = .sender
  var status: InvitationStatus = .completed
}

class AddressRequestUpdateDisplayableTests: XCTestCase {
  var sut: AddressRequestUpdateDisplayable!

  override func setUp() {
    super.setUp()
    self.sut = AddressRequestUpdateTestObject()
  }

  func testAlertAmountFormatterFullDecimals() {
    let number = NSDecimalNumber(integerAmount: 2_7823, currency: .BTC)
    let formattedNumber = self.sut.formattedAmountWithoutSymbol(for: number)
    XCTAssertEqual(formattedNumber, ".00027823")
  }

  func testAlertAmountFormatterPartialDecimal() {
    let number = NSDecimalNumber(integerAmount: 2_7800, currency: .BTC)
    let formattedNumber = self.sut.formattedAmountWithoutSymbol(for: number)
    XCTAssertEqual(formattedNumber, ".000278")
  }

  func testAlertAmountFormatterInteger() {
    let number = NSDecimalNumber(integerAmount: 2_0000_0000, currency: .BTC)
    let formattedNumber = self.sut.formattedAmountWithoutSymbol(for: number)
    XCTAssertEqual(formattedNumber, "2")
  }

  func testAlertAmountFormatterOverOne() {
    let number = NSDecimalNumber(integerAmount: 1_0002_7000, currency: .BTC)
    let formattedNumber = self.sut.formattedAmountWithoutSymbol(for: number)
    XCTAssertEqual(formattedNumber, "1.00027")
  }

}
