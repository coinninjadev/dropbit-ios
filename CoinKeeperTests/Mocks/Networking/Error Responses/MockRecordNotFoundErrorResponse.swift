//
//  MockRecordNotFoundErrorResponse.swift
//  DropBitTests
//
//  Created by Ben Winters on 12/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation

struct MockRecordNotFoundErrorResponse: ResponseCodable {

  static var sampleJSON: String {
    return """
    {
    "error": "FindUser: record not found",
    "message": "Unauthorized",
    "status": 401
    }
    """
  }

  static var requiredStringKeys: [KeyPath<MockRecordNotFoundErrorResponse, String>] {
    return []
  }

  static var optionalStringKeys: [WritableKeyPath<MockRecordNotFoundErrorResponse, String?>] {
    return []
  }

}
