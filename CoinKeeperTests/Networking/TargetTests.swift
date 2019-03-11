//
//  TargetTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 12/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import XCTest
import Alamofire
import Moya
import Foundation

class TargetTests: XCTestCase {

  func testUserTargetShouldUnverify_RecordNotFound() {
    let target = UserTarget.get
    let responseData = MockRecordNotFoundErrorResponse.sampleData
    let moyaError = MockMoyaError.unacceptableStatusCode(code: 401, responseData: responseData)

    guard let ckNetworkError = target.networkError(for: moyaError) else {
      XCTFail("Should return network error")
      return
    }

    guard case .shouldUnverify = ckNetworkError else {
      XCTFail("Should return .shouldUnverify, not \(ckNetworkError)")
      return
    }
  }

  func testUserTargetShouldUnverify_DeviceUUIDMismatch() {
    let target = UserTarget.get
    let responseData = MockDeviceUUIDMismatchErrorResponse.sampleData
    let moyaError = MockMoyaError.unacceptableStatusCode(code: 401, responseData: responseData)

    guard let ckNetworkError = target.networkError(for: moyaError) else {
      XCTFail("Should return network error")
      return
    }

    guard case .shouldUnverify = ckNetworkError else {
      XCTFail("Should return .shouldUnverify, not \(ckNetworkError)")
      return
    }
  }

  func testWalletTargetShouldUnverify_RecordNotFound() {
    let target = WalletTarget.get
    let responseData = MockRecordNotFoundErrorResponse.sampleData
    let moyaError = MockMoyaError.unacceptableStatusCode(code: 401, responseData: responseData)

    guard let ckNetworkError = target.networkError(for: moyaError) else {
      XCTFail("Should return network error")
      return
    }

    guard case .shouldUnverify = ckNetworkError else {
      XCTFail("Should return .shouldUnverify, not \(ckNetworkError)")
      return
    }
  }

  func testWalletTargetShouldUnverify_DeviceUUIDMismatch() {
    let target = WalletTarget.get
    let responseData = MockDeviceUUIDMismatchErrorResponse.sampleData
    let moyaError = MockMoyaError.unacceptableStatusCode(code: 401, responseData: responseData)

    guard let ckNetworkError = target.networkError(for: moyaError) else {
      XCTFail("Should return network error")
      return
    }

    guard case .shouldUnverify = ckNetworkError else {
      XCTFail("Should return .shouldUnverify, not \(ckNetworkError)")
      return
    }
  }

}
