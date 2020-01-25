//
//  WyreURLParserTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 10/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class WyreURLParserTests: XCTestCase {

  func testFullyFormedURLParsesCorrectly() {
    let expectedTransferID = "123transferid"
    let expectedOrderID = "456orderid"
    let expectedAccountId = "789accountid"
    let expectedDestinationAddress = "3HvgiuXMB2SHNsvvR4yWFr7kEGEHkzN8oH"
    let expectedFees = "0.00001"
    let expectedAmount = "0.05"

    let urlString = "\(DropBitUrlFactory.DropBitURL.scheme)://wyre?transferId=\(expectedTransferID)" +
    "&orderId=\(expectedOrderID)" +
    "&accountId=\(expectedAccountId)" +
    "&dest=\(expectedDestinationAddress)" +
    "&fees=\(expectedFees)" +
    "&destAmount=\(expectedAmount)"

    let parser = WyreURLParser(url: URL(string: urlString)!)

    XCTAssertNotNil(parser)
    XCTAssertEqual(parser?.transferID, expectedTransferID)
    XCTAssertEqual(parser?.orderID, expectedOrderID)
    XCTAssertEqual(parser?.accountID, expectedAccountId)
    XCTAssertEqual(parser?.destinationAddress, expectedDestinationAddress)
    XCTAssertEqual(parser?.fees, expectedFees)
    XCTAssertEqual(parser?.amount, expectedAmount)
  }

  func testMissingTransferIDReturnsNil() {
    let expectedOrderID = "456orderid"
    let expectedAccountId = "789accountid"
    let expectedDestinationAddress = "3HvgiuXMB2SHNsvvR4yWFr7kEGEHkzN8oH"
    let expectedFees = "0.00001"
    let expectedAmount = "0.05"

    let urlString = "\(DropBitUrlFactory.DropBitURL.scheme)wyre?" +
      "orderId=\(expectedOrderID)" +
      "&accountId=\(expectedAccountId)" +
      "&dest=\(expectedDestinationAddress)" +
      "&fees=\(expectedFees)" +
    "&destAmount=\(expectedAmount)"

    let parser = WyreURLParser(url: URL(string: urlString)!)

    XCTAssertNil(parser)
  }

  func testMissingOrderIDReturnsNil() {
    let expectedTransferID = "123transferid"
    let expectedAccountId = "789accountid"
    let expectedDestinationAddress = "3HvgiuXMB2SHNsvvR4yWFr7kEGEHkzN8oH"
    let expectedFees = "0.00001"
    let expectedAmount = "0.05"

    let urlString = "\(DropBitUrlFactory.DropBitURL.scheme)wyre?" +
      "transferId=\(expectedTransferID)" +
      "&accountId=\(expectedAccountId)" +
      "&dest=\(expectedDestinationAddress)" +
      "&fees=\(expectedFees)" +
    "&destAmount=\(expectedAmount)"

    let parser = WyreURLParser(url: URL(string: urlString)!)

    XCTAssertNil(parser)
  }

  func testMissingAccountIDReturnsNil() {
    let expectedTransferID = "123transferid"
    let expectedOrderID = "456orderid"
    let expectedDestinationAddress = "3HvgiuXMB2SHNsvvR4yWFr7kEGEHkzN8oH"
    let expectedFees = "0.00001"
    let expectedAmount = "0.05"

    let urlString = "\(DropBitUrlFactory.DropBitURL.scheme)wyre?transferId=\(expectedTransferID)" +
      "&orderId=\(expectedOrderID)" +
      "&dest=\(expectedDestinationAddress)" +
      "&fees=\(expectedFees)" +
    "&destAmount=\(expectedAmount)"

    let parser = WyreURLParser(url: URL(string: urlString)!)

    XCTAssertNil(parser)
  }

  func testMissingDestinationAddressReturnsNil() {
    let expectedTransferID = "123transferid"
    let expectedOrderID = "456orderid"
    let expectedAccountId = "789accountid"
    let expectedFees = "0.00001"
    let expectedAmount = "0.05"

    let urlString = "\(DropBitUrlFactory.DropBitURL.scheme)wyre?transferId=\(expectedTransferID)" +
      "&orderId=\(expectedOrderID)" +
      "&accountId=\(expectedAccountId)" +
      "&fees=\(expectedFees)" +
    "&destAmount=\(expectedAmount)"

    let parser = WyreURLParser(url: URL(string: urlString)!)

    XCTAssertNil(parser)
  }

  func testMissingFeesReturnsNil() {
    let expectedTransferID = "123transferid"
    let expectedOrderID = "456orderid"
    let expectedAccountId = "789accountid"
    let expectedDestinationAddress = "3HvgiuXMB2SHNsvvR4yWFr7kEGEHkzN8oH"
    let expectedAmount = "0.05"

    let urlString = "\(DropBitUrlFactory.DropBitURL.scheme)wyre?transferId=\(expectedTransferID)" +
      "&orderId=\(expectedOrderID)" +
      "&accountId=\(expectedAccountId)" +
      "&dest=\(expectedDestinationAddress)" +
    "&destAmount=\(expectedAmount)"

    let parser = WyreURLParser(url: URL(string: urlString)!)

    XCTAssertNil(parser)
  }

  func testMissingDestAmountReturnsNil() {
    let expectedTransferID = "123transferid"
    let expectedOrderID = "456orderid"
    let expectedAccountId = "789accountid"
    let expectedDestinationAddress = "3HvgiuXMB2SHNsvvR4yWFr7kEGEHkzN8oH"
    let expectedFees = "0.00001"

    let urlString = "\(DropBitUrlFactory.DropBitURL.scheme)wyre?transferId=\(expectedTransferID)" +
      "&orderId=\(expectedOrderID)" +
      "&accountId=\(expectedAccountId)" +
      "&dest=\(expectedDestinationAddress)" +
      "&fees=\(expectedFees)"

    let parser = WyreURLParser(url: URL(string: urlString)!)

    XCTAssertNil(parser)
  }

}
