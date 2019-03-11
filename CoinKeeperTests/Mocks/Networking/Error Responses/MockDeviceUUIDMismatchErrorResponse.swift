//
//  MockDeviceUUIDMismatchErrorResponse.swift
//  DropBitTests
//
//  Created by Ben Winters on 12/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation

struct MockDeviceUUIDMismatchErrorResponse: ResponseCodable {

  static var sampleJSON: String {
    return """
    {
    "error": "device_uuid mismatch",
    "message": "Unauthorized",
    "status": 401
    }
    """
  }

  static var requiredStringKeys: [KeyPath<MockDeviceUUIDMismatchErrorResponse, String>] {
    return []
  }

  static var optionalStringKeys: [WritableKeyPath<MockDeviceUUIDMismatchErrorResponse, String?>] {
    return []
  }

}
