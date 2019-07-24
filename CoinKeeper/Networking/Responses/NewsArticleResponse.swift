//
//  NewsArticleResponse.swift
//  DropBit
//
//  Created by Mitch on 10/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct NewsArticleResponse: ResponseDecodable {
  enum Source: String, Decodable {
    case reddit
    case ccn = "CCN"
    case ambcrypto
    case coindesk
    case cointelegraph
    case coinninja = "CoinNinja"
    case coinsquare
    case theblock
  }

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case link
    case thumbnail
    case description
    case source
    case author
    case pubTime
    case added
  }

  let id: String
  let title: String
  let link: String
  var thumbnail: String?
  var description: String?
  var source: String?
  var author: String?
  var pubTime: Date?
  var added: Date?

  var imageData: Data?

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(String.self, forKey: .id)
    self.title = try container.decode(String.self, forKey: .title)
    self.link = try container.decode(String.self, forKey: .link)
    self.thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
    self.description = try container.decodeIfPresent(String.self, forKey: .description)
    self.source = try container.decodeIfPresent(String.self, forKey: .source)
    self.author = try container.decodeIfPresent(String.self, forKey: .author)
    self.pubTime = try container.decodeIfPresent(Date.self, forKey: .pubTime)
    self.added = try container.decodeIfPresent(Date.self, forKey: .added)
  }

  func getFullSource() -> String {
    if let source = source, let added = added {
      return source + " • " + CKDateFormatter.displayFull.string(from: added)
    } else if let source = source {
      return source
    } else if let added = added {
      return CKDateFormatter.displayFull.string(from: added)
    } else {
      return ""
    }
  }
}

extension NewsArticleResponse {

  static var sampleJSON: String { return "" }

  static var requiredStringKeys: [KeyPath<NewsArticleResponse, String>] { return [] }

  static var optionalStringKeys: [WritableKeyPath<NewsArticleResponse, String?>] { return [] }

  static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .secondsSince1970
    return decoder
  }
}
