//
//  DataURIScheme.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/27/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//
//  https://en.m.wikipedia.org/wiki/Data_URI_scheme

import Foundation

struct DataURIScheme {

  enum Kind: String {
    case data
    case url
  }

  enum Media: String {
    case image
    case url
  }

  var kind: Kind
  var media: Media
  var payload: String

  init?(string: String) {
    let commaSplit = string.split(separator: ",")

    guard commaSplit.isNotEmpty,
      let forwardSlashSplit = commaSplit[safe: 0]?.split(separator: "/"),
      let colonSplit = forwardSlashSplit[safe: 0]?.split(separator: ":"),
      let kind = DataURIScheme.Kind(rawValue: String(colonSplit[safe: 0] ?? "")),
      let media = DataURIScheme.Media(rawValue: String(colonSplit[safe: 1] ?? "")),
      let payload = commaSplit[safe: 1]
      else { return nil }

    self.kind = kind
    self.media = media
    self.payload = String(payload)
  }
}
