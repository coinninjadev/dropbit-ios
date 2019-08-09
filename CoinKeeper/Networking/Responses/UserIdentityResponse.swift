//
//  UserIdentityResponse.swift
//  DropBit
//
//  Created by BJ Miller on 5/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct UserIdentityResponse: ResponseDecodable {

  /// The id of the identity, not the user
  let id: String
  let type: String
  let identity: String
  var hash: String?
  let status: String
}

extension UserIdentityResponse {
  var userIdentityType: UserIdentityType {
    return UserIdentityType(rawValue: type) ?? .phone
  }

  static var sampleJSON: String {
    return """
    {
      "id": "ad983e63-526d-4679-a682-c4ab052b20e1",
      "created_at": 1531921356,
      "updated_at": 1531921356,
      "type": "phone",
      "identity": "13305551212",
      "hash": "498803d5964adce8037d2c53da0c7c7a96ce0e0f99ab99e9905f0dda59fb2e49",
      "status": "pending-verification"
    }
    """
  }

  static var requiredStringKeys: [KeyPath<UserIdentityResponse, String>] {
    return [\.type, \.identity]
  }

  static var optionalStringKeys: [WritableKeyPath<UserIdentityResponse, String?>] {
    return [\.hash]
  }
}
