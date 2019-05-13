//
//  GetUserResponse.swift
//  CoinKeeper
//
//  Created by Ben Winters on 9/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum UserIdentityType: String {
  case phone
  case twitter
}

extension UserIdentityType {
  var identityDescription: String {
    switch self {
    case .phone: return "phone number"
    case .twitter: return "twitter account"
    }
  }
}

public struct CreateUserBody: Encodable {
  let type: String
  let identity: String

  init(phoneNumber: GlobalPhoneNumber) {
    self.type = UserIdentityType.phone.rawValue
    self.identity = phoneNumber.sanitizedGlobalNumber()
  }

  init(twitterCredentials: TwitterOAuthStorage) {
    self.type = UserIdentityType.twitter.rawValue
    self.identity = twitterCredentials.twitterUserId
  }
}

public struct VerifyUserBody: Encodable {
  let type: String
  let identity: String
  let code: String

  init(phoneNumber: GlobalPhoneNumber, code: String) {
    self.type = UserIdentityType.phone.rawValue
    self.identity = phoneNumber.sanitizedGlobalNumber()
    self.code = code
  }

  init(twitterCredentials: TwitterOAuthStorage) {
    self.type = UserIdentityType.twitter.rawValue
    self.identity = twitterCredentials.twitterUserId
    self.code = twitterCredentials.twitterOAuthToken + ":" + twitterCredentials.twitterOAuthTokenSecret
  }
}

public enum UserVerificationStatus: String {
  /// Use this case locally as the default, it should not be returned by the server
  case unverified
  case pending = "verification_pending"
  case verified
}

public struct UserPatchPrivateBody: Encodable {
  let `private`: Bool
}

public enum UserResponseKey: String, KeyPathDescribable {
  public typealias ObjectType = UserResponse
  case id, phoneNumberHash, createdAt, updatedAt, status, verificationTtl, verifiedAt, walletId
}

/// For /resend response: id: "" and timestamps: 0
public struct UserResponse: ResponseDecodable {

  let id: String
  let createdAt: Date
  let updatedAt: Date
  let status: String
  var walletId: String?

  // These properties are only available on the /user GET route
  let `private`: Bool?
  let identities: [PublicURLIdentity]?

}

extension UserResponse {

  static var sampleJSON: String {
    return """
    {
    "id": "ad983e63-526d-4679-a682-c4ab052b20e1",
    "created_at": 1531921356,
    "updated_at": 1531921356,
    "status": "pending-verification",
    "wallet_id": "f8e8c20e-ba44-4bac-9a96-44f3b7ae955d",
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
    }
    """
  }

  static var requiredStringKeys: [KeyPath<UserResponse, String>] {
    return [\.status]
  }

  static var optionalStringKeys: [WritableKeyPath<UserResponse, String?>] {
    return [\.walletId]
  }

}

struct UserPublicURLInfo {
  let `private`: Bool
  let identities: [PublicURLIdentity]

  var primaryIdentity: PublicURLIdentity? {
    return identities.sorted().first
  }

  var isEnabled: Bool {
    return !`private`
  }

}

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
