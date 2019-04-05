//
//  CurrencyStringValidatorTests.swift
//  DropBitTests
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation
import XCTest

class CurrencyStringValidatorTests: XCTestCase {
  var sut: CurrencyStringValidator!

  override func setUp() {
    super.setUp()
    self.sut = CurrencyStringValidator()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  func testNonNumberThrowsNotANumberError() {
    do {
      try self.sut.validate(value: "")
      XCTFail("empty string should throw error")
    } catch let error as CurrencyStringValidatorError {
      XCTAssertEqual(error, .notANumber, "error should be .notANumber")
    } catch {
      XCTFail("error should be CurrencyStringValidatorError")
    }
  }

  func testUSZeroThrowsZeroError() {
    do {
      try self.sut.validate(value: "0.0")
      XCTFail("0.0 should throw error")
    } catch let error as CurrencyStringValidatorError {
      XCTAssertEqual(error, .isZero, "error should be .isZero")
    } catch {
      XCTFail("error should be CurrencyStringValidatorError")
    }
  }

  func testFRZeroThrowsZeroError() {
    self.sut = CurrencyStringValidator(locale: .FR)
    do {
      try self.sut.validate(value: "0,0")
      XCTFail("0,0 should throw error")
    } catch let error as CurrencyStringValidatorError {
      XCTAssertEqual(error, .isZero, "error should be .isZero")
    } catch {
      XCTFail("error should be CurrencyStringValidatorError")
    }
  }

  func testValidUSValueDoesNotThrow() {
    self.sut = CurrencyStringValidator(locale: .US)
    XCTAssertNoThrow(try self.sut.validate(value: "2.0"),
                     "valid value should not throw")
    XCTAssertNoThrow(try self.sut.validate(value: "0.5"),
                     "valid value should not throw")
    XCTAssertNoThrow(try self.sut.validate(value: "0.00000001"),
                     "valid value should not throw")
  }

  func testValidFRValueDoesNotThrow() {
    self.sut = CurrencyStringValidator(locale: .FR)
    XCTAssertNoThrow(try self.sut.validate(value: "2,0"),
                     "valid value should not throw")
    XCTAssertNoThrow(try self.sut.validate(value: "0,5"),
                     "valid value should not throw")
    XCTAssertNoThrow(try self.sut.validate(value: "0,00000001"),
                     "valid value should not throw")
  }

  func testValidLTValueDoesNotThrow() {
    self.sut = CurrencyStringValidator(locale: .LT)
    XCTAssertNoThrow(try self.sut.validate(value: "2,0"),
                     "valid value should not throw")
    XCTAssertNoThrow(try self.sut.validate(value: "0,5"),
                     "valid value should not throw")
    XCTAssertNoThrow(try self.sut.validate(value: "0,00000001"),
                     "valid value should not throw")
  }

}

extension Locale {

  static var FR: Locale { // France
    return Locale(identifier: "fr_FR")
  }

  static var LT: Locale { // Lithuania
    return Locale(identifier: "lt_LT")
  }

}
