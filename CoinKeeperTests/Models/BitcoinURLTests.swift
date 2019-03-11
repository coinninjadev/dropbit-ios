//
//  BitcoinURLTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 10/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class BitcoinURLTests: XCTestCase {

  let validAddress = TestHelpers.mockValidBitcoinAddress()

  func test_initWithValidAddressString() {
    let bitcoinURL = BitcoinURL(string: validAddress)
    XCTAssertNotNil(bitcoinURL, "init should succeed with only address in string")
  }

  func test_Valid_bitcoinUrl_Contains_AmountAndAddress() {
    let string = "bitcoin:\(validAddress)?amount=1.2"

    let actual = BitcoinURL(string: string)
    let expectedAddress = validAddress
    let expectedAmount = 1.2

    XCTAssertEqual(actual?.components.address, expectedAddress)
    XCTAssertEqual(actual?.components.amount?.doubleValue, expectedAmount)
  }

  func test_InvalidAmount_BitcoinURL_DropsAfter8thDigit() {
    let string = "bitcoin:\(validAddress)?amount=1.123456789"

    let actual = BitcoinURL(string: string)
    let expectedAmount = 1.12345678
    let expectedAddress = validAddress

    XCTAssertEqual(actual?.components.address, expectedAddress)
    XCTAssertEqual(actual?.components.amount?.doubleValue, expectedAmount)
  }

  func test_InvalidAddress_bitcoinUrl_ReturnsNil() {
    let string = "bitcoin:abc?amount=1.2"

    let actual = BitcoinURL(string: string)

    XCTAssertNil(actual)
  }

  func test_ValidAddress_WithoutAmount_Contains_Address() {
    let string = "bitcoin:\(validAddress)"

    let actual = BitcoinURL(string: string)
    let expectedAddress = validAddress

    XCTAssertEqual(actual?.components.address, expectedAddress)
    XCTAssertNil(actual?.components.amount)
  }

  func test_NoAddress_WithAmount_ReturnsNil() {
    let string = "bitcoin:amount=1.2"

    let actual = BitcoinURL(string: string)

    XCTAssertNil(actual)
  }

  func test_roundedAmount_dropsAfter8thDigit() {
    let amountString = "1.123456789"
    guard let number = BitcoinURLComponents.roundedAmount(fromString: amountString) else {
      XCTFail("Rounding should return NSDecimalNumber")
      return
    }

    let digits = number.significantFractionalDecimalDigits
    XCTAssertTrue(digits <= 8, "decimal places should be <= 8 after rounding, actual: \(digits)")
  }

  func test_r_PaymentRequestParsesCorrectly() {
    let expectedRequestURL = "https://merchant.com/pay.php?h=2a8628fc2fbe"

    let stringA = "bitcoin:?r=https://merchant.com/pay.php?h%3D2a8628fc2fbe"
    let urlA = BitcoinURL(string: stringA)
    let parsedRequestA = urlA?.components.paymentRequest?.absoluteString

    XCTAssertNil(urlA?.components.address, "address should be nil, not an empty string")

    XCTAssertEqual(parsedRequestA, expectedRequestURL)

    let stringB = "bitcoin:\(validAddress)?amount=0.11&r=https://merchant.com/pay.php?h%3D2a8628fc2fbe"
    let urlB = BitcoinURL(string: stringB)
    let parsedRequestB = urlB?.components.paymentRequest?.absoluteString

    XCTAssertEqual(parsedRequestB, expectedRequestURL)
  }

  func test_r_BitpayPaymentRequestParsesCorrectly() {
    let expectedRequestURL = "https://bitpay.com/i/FTZtAAwrUCsHX9trpjSKum"
    let urlString = "bitcoin:?r=https://bitpay.com/i/FTZtAAwrUCsHX9trpjSKum"
    let bitcoinURL = BitcoinURL(string: urlString)
    let parsedRequest = bitcoinURL?.components.paymentRequest?.absoluteString

    XCTAssertNil(bitcoinURL?.components.address, "address should be nil, not an empty string")
    XCTAssertEqual(parsedRequest, expectedRequestURL)
  }

  func test_request_PaymentRequestParsesCorrectly() {
    let expectedRequestURL = "https://merchant.com/pay.php?h=2a8628fc2fbe"

    let stringA = "bitcoin:?request=https://merchant.com/pay.php?h%3D2a8628fc2fbe"
    let urlA = BitcoinURL(string: stringA)
    let parsedRequestA = urlA?.components.paymentRequest?.absoluteString

    XCTAssertEqual(parsedRequestA, expectedRequestURL)

    let stringB = "bitcoin:\(validAddress)?amount=0.11&request=https://merchant.com/pay.php?h%3D2a8628fc2fbe"
    let urlB = BitcoinURL(string: stringB)
    let parsedRequestB = urlB?.components.paymentRequest?.absoluteString

    XCTAssertEqual(parsedRequestB, expectedRequestURL)
  }

  func test_bareBIP70URLParsesCorrectly() {
    let expectedURLString = "bitcoin:?r=https://merchant.com/pay.php?h%3D2a8628fc2fbe"
    let bareURL = "https://merchant.com/pay.php?h%3D2a8628fc2fbe"
    let bitcoinURL = BitcoinURL(string: bareURL)
    let repairedURLFullString = bitcoinURL?.absoluteString
    XCTAssertNotNil(repairedURLFullString)
    XCTAssertEqual(expectedURLString, repairedURLFullString)
  }

}
