//
//  BitcoinAddressValidatorTests.swift
//  DropBitTests
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation
import XCTest

class BitcoinAddressValidatorTests: XCTestCase {
  var sut: BitcoinAddressValidator!

  override func setUp() {
    super.setUp()
    self.sut = BitcoinAddressValidator()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  func testInvalidBase58CheckAddressesThrowError() {
    TestHelpers.invalidBase58CheckAddresses().forEach { address in
      do {
        try self.sut.validate(value: address)
        XCTFail("invalid address should throw error")
      } catch let error as BitcoinAddressValidatorError {
        XCTAssertEqual(error, .notBase58CheckValid,
                       "error should be .notBase58CheckValid")
      } catch {
        XCTFail("error should be BitcoinAddressValidatorError")
      }
    }
  }

  func testValidBase58CheckAddressesReturnValid() {
    for address in TestHelpers.validBase58CheckAddresses() {
      XCTAssertNoThrow(try self.sut.validate(value: address),
                       "\(address) should be valid")
    }
  }

  func testValidBTCAddressDoesNotThrow() {
    let address = TestHelpers.mockValidBitcoinAddress()
    XCTAssertNoThrow(try self.sut.validate(value: address),
                     "valid BTC address should not throw")
  }

  func testAddressWithEmptyStringReturnsNil() {
    let sanitizedResult = self.sut.sanitizedAddress(in: "")
    XCTAssertNil(sanitizedResult, "sanitized address should be nil")
  }

  func testAddressWithWhiteSpaceReturnsNil() {
    let sanitizedResult = self.sut.sanitizedAddress(in: "     ")
    XCTAssertNil(sanitizedResult, "sanitized address should be nil")
  }

  func testInvalidAddressReturnsNil() {
    let invalidAddress = "2NrsjyivitShUiv9FJvjLH7Nh1ZZptumwW"
    let sanitizedResult = self.sut.sanitizedAddress(in: invalidAddress)
    XCTAssertNil(sanitizedResult, "result should be nil")
  }

  func testValidAddressReturnsValidAddress() {
    let validAddress = "13r1jyivitShUiv9FJvjLH7Nh1ZZptumwW"
    let sanitizedResult = self.sut.sanitizedAddress(in: validAddress)
    XCTAssertEqual(sanitizedResult, validAddress, "valid address should be returned")
  }

  func testDirtyValidAddressReturnsValidAddress() {
    let validAddress = "13r1jyivitShUiv9FJvjLH7Nh1ZZptumwW"
    let dirtyValidAddress = "Hello, here is my Bitcoin address: \(validAddress)."
    let sanitizedResult = self.sut.sanitizedAddress(in: dirtyValidAddress)
    XCTAssertEqual(sanitizedResult, validAddress, "result should equal valid address")
  }

  func testFullAddressURLReturnsValidAddress() {
    let validAddress = "13r1jyivitShUiv9FJvjLH7Nh1ZZptumwW"
    let validBitcoinURL = "bitcoin:\(validAddress)?amount=1.2"
    let sanitizedResult = self.sut.sanitizedAddress(in: validBitcoinURL)
    XCTAssertEqual(sanitizedResult, validAddress, "result should equal valid address")
  }

}
