//
//  NewsArticleResponse.swift
//  DropBit
//
//  Created by Mitch on 10/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct NewsArticleResponse: ResponseDecodable {
  enum Source: String, Decodable {
    case reddit
    case ccn = "CCN"
    case ambcrypto
    case coindesk
    case cointelegraph
    case coinninja = "CoinNinja"
    case coinsquare
  }

  let id: String
  let title: String
  let link: String
  let thumbnail: String?
  let description: String?
  let source: String?
  let author: String?
  let pubTime: Date?
  let added: Date?
  let bullshit: String
  
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
