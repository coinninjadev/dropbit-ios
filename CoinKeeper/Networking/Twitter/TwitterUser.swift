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
  let location: String?
  let description: String?
  let url: String?
  let followersCount: Int?
  let friendsCount: Int?
  let profileImageUrlHttps: String?

  var profileImageURL: URL? {
    return profileImageUrlHttps.flatMap { URL(string: $0) }
  }

  var profileImageData: Data?
}

