//
//  CoinNinjaTargetTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 11/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya
import XCTest
@testable import DropBit

class CoinNinjaTargetTests: XCTestCase {

  enum NetworkError: Error {
    case generalWithoutStatusCode
  }

  func testGeneralNetworkErrorMapsToReachabilityFailed() {
    let target = WalletCheckInTarget.get
    let originalError = MoyaError.underlying(NetworkError.generalWithoutStatusCode, nil)
    let mappedError = target.networkError(for: originalError)

    guard let networkError = mappedError, case .reachabilityFailed = networkError else {
      XCTFail("A network error without a status code should be mapped to .reachabilityFailed")
      return
    }
  }

}
