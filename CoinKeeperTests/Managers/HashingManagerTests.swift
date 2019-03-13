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
import PhoneNumberKit

class HashingManagerTests: XCTestCase {

  var sut: HashingManager!

  let kit = PhoneNumberKit()

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

  func testPhoneNumberHashGeneration_US() {
    let phoneNumber = GlobalPhoneNumber(countryCode: 1, nationalNumber: "3475551212")
    let expectedHash = "527e4d5386af738d29a6a66736e3d3199a3861237fadc9ed80ff46d58608642e"

    do {
      let salt = try self.sut.salt()
      let hashedNumber = self.sut.hash(phoneNumber: phoneNumber, salt: salt, parsedNumber: nil, kit: self.kit)
      XCTAssertEqual(hashedNumber, expectedHash, "hashes should be equal")
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  // Phone numbers below are examples included in PhoneNumberKit

  func testPhoneNumberHashGeneration_AR() {
    let phoneNumberWithPrefix = GlobalPhoneNumber(countryCode: 54, nationalNumber: "91123456789")
    let phoneNumberWithoutPrefix = GlobalPhoneNumber(countryCode: 54, nationalNumber: "1123456789")
    let expectedHash = "2d4c4bdfa189c8e8240b82788df37d77f7d95d4f87bc1511b1b7ad87139cef70"

    do {
      let salt = try self.sut.salt()
      let hashedNumberWithPrefix = self.sut.hash(phoneNumber: phoneNumberWithPrefix, salt: salt,
                                                 parsedNumber: nil, kit: self.kit)
      let hashedNumberWithoutPrefix = self.sut.hash(phoneNumber: phoneNumberWithoutPrefix, salt: salt,
                                                    parsedNumber: nil, kit: self.kit)

      XCTAssertEqual(hashedNumberWithPrefix, expectedHash, "hashes should be equal")
      XCTAssertEqual(hashedNumberWithPrefix, hashedNumberWithoutPrefix, "hashes should be equal")
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testPhoneNumberHashGeneration_BR() {
    let phoneNumber = GlobalPhoneNumber(countryCode: 55, nationalNumber: "11961234567")
    let expectedHash = "a353a8e312a5cc0e368c771c177e67c34c6580d6f9455df1d4d5d2aa53af15f1"

    do {
      let salt = try self.sut.salt()
      let hashedNumber = self.sut.hash(phoneNumber: phoneNumber, salt: salt, parsedNumber: nil, kit: self.kit)
      XCTAssertEqual(hashedNumber, expectedHash, "hashes should be equal")
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testPhoneNumberHashGeneration_MX() {
    let phoneNumber = GlobalPhoneNumber(countryCode: 52, nationalNumber: "12221234567")
    let expectedHash = "bc082b2e701d4fe3c96b270f88a626bc0cd33453aa1aa6042606fe3dcb33fdf0"

    do {
      let salt = try self.sut.salt()
      let hashedNumber = self.sut.hash(phoneNumber: phoneNumber, salt: salt, parsedNumber: nil, kit: self.kit)
      XCTAssertEqual(hashedNumber, expectedHash, "hashes should be equal")
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testPhoneNumberHashGeneration_SM() {
    let phoneNumber = GlobalPhoneNumber(countryCode: 378, nationalNumber: "66661212")
    let expectedHash = "20e5dd53713801a9b0e65b92f99263b5c0086d1e383e3e8d12e15a75b424e067"

    do {
      let salt = try self.sut.salt()
      let hashedNumber = self.sut.hash(phoneNumber: phoneNumber, salt: salt, parsedNumber: nil, kit: self.kit)
      XCTAssertEqual(hashedNumber, expectedHash, "hashes should be equal")
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

}
