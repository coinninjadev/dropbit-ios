//
//  CompositeValidatorTests.swift
//  DropBitTests
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation
import XCTest

class CompositeValidatorTests: XCTestCase {
  var sut: CompositeValidator<String>!

  override func setUp() {
    super.setUp()
    self.sut = CompositeValidator<String>(validators: [StringEmptyValidator(), BitcoinAddressValidator()])
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  func testEmptyStringThrowsEmptyError() {
    do {
      try self.sut.validate(value: "")
      XCTFail("should throw error for empty string")
    } catch let error as StringEmptyValidatorError {
      XCTAssertEqual(error, .isEmpty, "error should be .isEmpty")
    } catch {
      XCTFail("should throw StringEmptyValidatorError")
    }
  }

  func testInvalidBTCAddressError() {
    do {
      try self.sut.validate(value: "2398vubn2934v834d")
      XCTFail("invalid BTC address should throw error")
    } catch let error as BitcoinAddressValidatorError {
      XCTAssertEqual(error, .notBase58CheckValid,
                     "error should be .notBase58CheckValid")
    } catch {
      XCTFail("should throw BitcoinAddressValidatorError")
    }
  }

  func testValidBTCAddressDoesNotThrowError() {
    let address = TestHelpers.mockValidBitcoinAddress()
    XCTAssertNoThrow(try self.sut.validate(value: address),
                     "valid BTC addres should not throw error")
  }
}
