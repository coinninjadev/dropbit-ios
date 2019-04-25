//
//  DropBitMeResponse.swift
//  DropBit
//
//  Created by Ben Winters on 4/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Moya

/// An object nested within the UserResponse
public struct DropBitMeResponse: ResponseCodable {
  let id: String
  let enabled: Bool

  static var sampleJSON: String {
    return """
    {
    "id": "abcdef123456"
    "enabled": true
    }
    """
  }

  static var requiredStringKeys: [KeyPath<DropBitMeResponse, String>] {
    return [\.id]
  }

  static var optionalStringKeys: [WritableKeyPath<DropBitMeResponse, String?>] {
    return []
  }

}
