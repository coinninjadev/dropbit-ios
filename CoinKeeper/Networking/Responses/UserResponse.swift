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

public struct CreateUserBody: Encodable {
  let type: String
  let identity: String

  init(phoneNumber: GlobalPhoneNumber) {
    self.type = UserIdentityType.phone.rawValue
    self.identity = phoneNumber.sanitizedGlobalNumber()
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
}

public enum UserVerificationStatus: String {
  /// Use this case locally as the default, it should not be returned by the server
  case unverified
  case pending = "verification_pending"
  case verified
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

}

extension UserResponse {

  static var sampleJSON: String {
    return """
    {
    "id": "ad983e63-526d-4679-a682-c4ab052b20e1",
    "created_at": 1531921356,
    "updated_at": 1531921356,
    "status": "pending-verification",
    "wallet_id": "f8e8c20e-ba44-4bac-9a96-44f3b7ae955d"
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
