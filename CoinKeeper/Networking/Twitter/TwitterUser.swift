//
//  TwitterUser.swift
//  DropBit
//
//  Created by BJ Miller on 5/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct TwitterUser: Decodable {
  static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }

  let idStr: String
  let name: String
  let screenName: String
  let description: String?
  let url: String?
  let verified: Bool
  let profileImageUrlHttps: String?

  var profileImageURL: URL? {
    return profileImageUrlHttps.flatMap { URL(string: $0) }
  }

  var profileImageData: Data?
}

extension TwitterUser {
  var formattedScreenName: String {
    guard !screenName.starts(with: "@") else { return screenName }
    return "@" + screenName
  }

  static func emptyInstance() -> TwitterUser {
    return TwitterUser(idStr: "",
                       name: "",
                       screenName: "",
                       description: nil,
                       url: nil,
                       verified: false,
                       profileImageUrlHttps: nil,
                       profileImageData: nil)
  }
}
