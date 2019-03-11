//
//  StringEmptyValidatorTests.swift
//  DropBitTests
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation
import XCTest

class StringEmptyValidatorTests: XCTestCase {
  var sut: StringEmptyValidator!

  override func setUp() {
    super.setUp()
    self.sut = StringEmptyValidator()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  func testStringEmptyValidatorThrowsIsEmptyError() {
    let failureMessage = "isEmpty error should be returned"
    do {
      try self.sut.validate(value: "")
      XCTFail(failureMessage)
    } catch {
      guard let vError = error as? StringEmptyValidatorError, case .isEmpty = vError else {
        XCTFail(failureMessage)
        return
      }
    }
  }

  func testValidInputDoesNotThrow() {
    XCTAssertNoThrow(try self.sut.validate(value: "Not empty"),
                     "non-empty string should be valid")
  }
}
