//
//  ResponseStringsTestable.swift
//  DropBitTests
//
//  Created by Ben Winters on 11/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation
import XCTest

protocol EmptyStringCopyable: ResponseDecodable {
  func copyWithEmptyRequiredStrings() -> Self
}

protocol ResponseStringsTestable: ResponseDecodingTestable where ResponseType: EmptyStringCopyable {
  /// All implementations of this can be identical using the extensions below and on EmptyStringCopyable
  func testEmptyStringThrowsError()
}

extension ResponseStringsTestable where Self: XCTest {
  var emptyStringTestMessage: String {
    return "Empty strings should throw error"
  }

  var emptyStringNoThrowMessage: String {
    return "Empty strings should not throw error"
  }

  var emptyStringErrorTypeMessage: String {
    return "Empty string error should be CKNetworkError.invalidValue"
  }
}

extension Error {
  var isNetworkInvalidValueError: Bool {
    if let networkError = self as? CKNetworkError, case .invalidValue = networkError {
      return true
    } else {
      return false
    }
  }
}
