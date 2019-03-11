//
//  HashingManagerTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 2/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation
import XCTest

class HashingManagerTests: XCTestCase {

  var sut: HashingManager!

  override func setUp() {
    super.setUp()
    self.sut = HashingManager()
  }

  override func tearDown() {
    super.tearDown()
    self.sut = nil
  }

  func testSaltReturnsData() {
    do {
      _ = try sut.salt()
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testPhoneNumberHashGeneration() {
    let phoneNumber = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3475551212")
    let expectedHash = "527e4d5386af738d29a6a66736e3d3199a3861237fadc9ed80ff46d58608642e"

    do {
      let salt = try self.sut.salt()
      let hashedNumber = self.sut.hash(phoneNumber: phoneNumber, salt: salt)
      XCTAssertEqual(hashedNumber, expectedHash, "hashes should be equal")
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

}
