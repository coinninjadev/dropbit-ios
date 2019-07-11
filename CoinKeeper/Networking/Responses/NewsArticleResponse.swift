//
//  NewsArticleResponse.swift
//  DropBit
//
//  Created by Mitch on 10/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct NewsArticleContainer: Decodable {
  var newsArr: [NewsArticleResponse]
}

public struct NewsArticleResponse: ResponseDecodable {
  enum Source: String, Decodable {
    case reddit
    case ccn = "CCN"
    case ambcrypto
    case coindesk
    case cointelegraph
    case coinninja
    case coinsquare
  }

  let id: String
  let title: String
  let link: String
  let thumbnail: String?
  let description: String
  let source: String
  let author: String
  let pubTime: Date
  let added: Date
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
