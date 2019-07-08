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
    case ccn
    case ambcrypto
    case coindesk
    case cointelegraph
    case coinninja
    case coinsquare
    case btc
  }

  let id: String
  let title: String
  let desc: String
  let link: String
  let thumb: String
  let pubTime: String
  let added: String
  let source: String
  let hidden: String
  let newTime: String
  let num: Int
}

extension NewsArticleResponse {
  
  static var sampleJSON: String { return "" }
  
  static var requiredStringKeys: [KeyPath<NewsArticleResponse, String>] { return [] }
  
  static var optionalStringKeys: [WritableKeyPath<NewsArticleResponse, String?>] { return [] }
  
}
