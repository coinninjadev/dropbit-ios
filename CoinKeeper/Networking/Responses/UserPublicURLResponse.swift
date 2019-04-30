//
//  DropBitMeResponse.swift
//  DropBit
//
//  Created by Ben Winters on 4/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Moya

public struct UserPublicURLBody: Encodable {
  let `private`: Bool
}

typealias UserPublicURLInfo = UserPublicURLResponse

struct PublicURLIdentity: ResponseCodable, Comparable {

  let type: String
  let handle: String

  static var sampleJSON: String {
    return """
    {
    "type": "phone"
    "handle": "abcdef123456"
    }
    """
  }

  init(fullPhoneHash: String) {
    self.type = UserIdentityType.phone.rawValue
    self.handle = String(fullPhoneHash.prefix(12))
  }

  static var requiredStringKeys: [KeyPath<PublicURLIdentity, String>] {
    return [\.type, \.handle]
  }

  static var optionalStringKeys: [WritableKeyPath<PublicURLIdentity, String?>] {
    return []
  }

  static func < (lhs: PublicURLIdentity, rhs: PublicURLIdentity) -> Bool {
    guard let lhsType = UserIdentityType(rawValue: lhs.type) else {
      return false
    }

    return lhsType == .twitter
  }

}

public struct UserPublicURLResponse: ResponseCodable {
  let `private`: Bool
  let identities: [PublicURLIdentity]

  static var sampleJSON: String {
    return """
    "private": false,
    "identities": [
      {
        "type": "phone",
        "handle": "abcdef123456"
      },
      {
        "type": "twitter",
        "handle": "jack"
      }
    ]
    """
  }

  var primaryIdentity: PublicURLIdentity? {
    return identities.sorted().first
  }

  var isEnabled: Bool {
    return !`private`
  }

  static var requiredStringKeys: [KeyPath<UserPublicURLResponse, String>] {
    return []
  }

  static var optionalStringKeys: [WritableKeyPath<UserPublicURLResponse, String?>] {
    return []
  }

}
