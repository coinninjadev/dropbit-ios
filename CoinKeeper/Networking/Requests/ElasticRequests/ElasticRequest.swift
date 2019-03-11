//
//  ElasticRequest.swift
//  DropBit
//
//  Created by Mitch on 9/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct ElasticRequest: Encodable {
  let query: ElasticQuery
}

/// Customization of the query keys should be done by subclassing
public class ElasticQuery: Encodable {
  let range: ElasticRange?
  let script: ElasticScript?
  let term: JSONValue?
  let terms: JSONValue?

  init(range: ElasticRange? = nil,
       script: ElasticScript? = nil,
       term: JSONValue? = nil,
       terms: JSONValue? = nil) {
    self.range = range
    self.script = script
    self.term = term
    self.terms = terms
  }
}

public struct ElasticRange: Encodable {
  let createdAt: JSONValue

  init(createdAt: Date) {
    self.createdAt = .object(["gte": .string(CKDateFormatter.rfc3339.string(from: createdAt))])
  }
}

public struct ElasticScript: Encodable {
  let script: JSONValue

  init(id: String, version: String) {
    script = .object(["id": .string(id),
                      "params": .object(["version": .string(version)])])
  }
}

public struct ElasticTerm {

  static func level(_ level: GlobalMessage.Level) -> JSONValue {
    return .object(["level": .string(level.rawValue)])
  }

}

public struct ElasticTerms {

  static func object(withPlatforms platforms: [GlobalMessage.Platform]) -> JSONValue {
    let strings = platforms.compactMap { $0.rawValue }
    let arrayValue = stringsToArrayValue(strings)
    return .object(["platform": arrayValue])
  }

  static func object(withPhoneNumberHashes hashes: [String]) -> JSONValue {
    let arrayValue = stringsToArrayValue(hashes)
    return .object(["phone_number_hash": arrayValue])
  }

  private static func stringsToArrayValue(_ strings: [String]) -> JSONValue {
    return .array(strings.map { .string($0) })
  }

}

extension ElasticRequest: BodyEncodable {
  static var sampleJSON: String {
    return """
    {
    "query": {
    "range": {
    "created_at": {
    "gte": "2006-01-02T15:04:05Z07:00"
    }
    },
    "script": {
    "script": {
    "id": "semver",
    "params": {
    "version": "1.0.1"
    }
    }
    },
    "term": {
    "level": "warn"
    },
    "terms": {
    "platform": [
    "ios"
    ]
    }
    }
    }
    """
  }

}
