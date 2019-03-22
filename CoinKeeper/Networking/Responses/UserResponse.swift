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

public struct UserResponse: ResponseDecodable {

  let id: String
  let phoneNumberHash: String
  let createdAt: Date
  let updatedAt: Date
  let status: String
  let verificationTtl: Date?
  let verifiedAt: Date?
  var walletId: String?

}

extension UserResponse {

  static var sampleJSON: String {
    return """
    {
    "id": "ad983e63-526d-4679-a682-c4ab052b20e1",
    "phone_number_hash": "498803d5964adce8037d2c53da0c7c7a96ce0e0f99ab99e9905f0dda59fb2e49",
    "created_at": 1531921356,
    "updated_at": 1531921356,
    "status": "pending-verification",
    "verification_ttl": 1531921356,
    "verified_at": 1531921356,
    "wallet_id": "f8e8c20e-ba44-4bac-9a96-44f3b7ae955d"
    }
    """
  }

  static var requiredStringKeys: [KeyPath<UserResponse, String>] {
    return [\.id, \.phoneNumberHash, \.status]
  }

  static var optionalStringKeys: [WritableKeyPath<UserResponse, String?>] {
    return [\.walletId]
  }

}
