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
    let invalidAddress = TestHelpers.mockInvalidBitcoinAddress()
    let sanitizedResult = self.sut.sanitizedAddress(in: invalidAddress)
    XCTAssertNil(sanitizedResult, "result should be nil")
  }

  func testValidAddressReturnsValidAddress() {
    let validAddress = TestHelpers.mockValidBitcoinAddress()
    let sanitizedResult = self.sut.sanitizedAddress(in: validAddress)
    XCTAssertEqual(sanitizedResult, validAddress, "valid address should be returned")
  }

  func testDirtyValidAddressReturnsValidAddress() {
    let validAddress = TestHelpers.mockValidBitcoinAddress()
    let dirtyValidAddress = "Hello, here is my Bitcoin address: \(validAddress)."
    let sanitizedResult = self.sut.sanitizedAddress(in: dirtyValidAddress)
    XCTAssertEqual(sanitizedResult, validAddress, "result should equal valid address")
  }

  func testFullAddressURLReturnsValidAddress() {
    let validAddress = TestHelpers.mockValidBitcoinAddress()
    let validBitcoinURL = "bitcoin:\(validAddress)?amount=1.2"
    let sanitizedResult = self.sut.sanitizedAddress(in: validBitcoinURL)
    XCTAssertEqual(sanitizedResult, validAddress, "result should equal valid address")
  }

  func testValidBech32AddressReturnsValid() {
    let validBech32Address = "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
    XCTAssertNoThrow(try self.sut.validate(value: validBech32Address))
  }

  func testInvalidBech32AddressThrowsError() {
    let invalidBech32Address = "BC1QW508D6QEJXTDG4Y5R3ZARVAYR0C5XW7KV8F3T4"
    XCTAssertThrowsError(try self.sut.validate(value: invalidBech32Address))

    do {
      try self.sut.validate(value: invalidBech32Address)
      XCTFail("should throw")
    } catch {
      if let bech32Error = error as? BitcoinAddressValidatorError {
        XCTAssertEqual(bech32Error, .notBech32Valid)
      } else {
        XCTFail("error should be notBech32Valid")
      }
    }
  }

}
