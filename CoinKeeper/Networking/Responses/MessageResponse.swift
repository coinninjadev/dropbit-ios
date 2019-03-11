//
//  MessageResponse.swift
//  CoinKeeper
//
//  Created by Mitch on 9/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Moya

struct MessageMetadata: ResponseDecodable {
  let displayAt: Double
  let displayTtl: Double

  static var sampleJSON: String {
    return """
    {
    "display_at": 1531921356,
    "display_ttl": 1531921356
    }
    """
  }

  static var requiredStringKeys: [KeyPath<MessageMetadata, String>] { return [] }
  static var optionalStringKeys: [WritableKeyPath<MessageMetadata, String?>] { return [] }
}

struct MessageResponse: ResponseDecodable {

  var link: URL? {
    return url.flatMap { URL(string: $0) }
  }

  let id: String
  let createdAt: Double
  let updatedAt: Double
  let subject: String
  let body: String
  var url: String?
  let level: GlobalMessage.Level
  let metadata: MessageMetadata?
  let platform: GlobalMessage.Platform
  let priority: Int
  let publishedAt: Double
  var version: String?
}

extension MessageResponse {

  static var sampleJSON: String {
    return """
    {
    "id": "380838b1-7cb2-421b-8d1c-5d9e58b99dc7",
    "created_at": 1531921356,
    "updated_at": 1531921356,
    "subject": "Sample subject/title",
    "body": "Sample body/description content",
    "level": "info",
    "metadata": \(MessageMetadata.sampleJSON),
    "platform": "all",
    "priority": 0,
    "published_at": 1531921356,
    "url": "https://coinninja.com",
    "version": "~> 1.0.1"
    }
    """
  }

  static var requiredStringKeys: [KeyPath<MessageResponse, String>] {
    return [\.id, \.subject, \.body]
  }

  static var optionalStringKeys: [WritableKeyPath<MessageResponse, String?>] {
    return [\.url, \.version]
  }
}

extension MessageResponse: Comparable {
  static func < (lhs: MessageResponse, rhs: MessageResponse) -> Bool {
    return lhs.priority < rhs.priority
  }

  static func == (lhs: MessageResponse, rhs: MessageResponse) -> Bool {
    return lhs.level == rhs.level && lhs.level.displayPriority == rhs.level.displayPriority
  }
}
