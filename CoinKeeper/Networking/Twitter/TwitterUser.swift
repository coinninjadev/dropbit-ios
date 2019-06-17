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
    return profileImageUrlHttps
      .map { $0.replacingOccurrences(of: "_normal.", with: ".") }
      .flatMap { URL(string: $0) }
  }

  var profileImageData: Data?
}

extension TwitterUser {
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

extension TwitterUser: TwitterUserFormattable {
  var twitterScreenName: String {
    return screenName
  }
}

protocol TwitterUserFormattable {
  var twitterScreenName: String { get }
}

extension TwitterUserFormattable {
  var formattedScreenName: String {
    let isFormatted = twitterScreenName.starts(with: "@")
    return isFormatted ? twitterScreenName : "@\(twitterScreenName)"
  }
}
