//
//  MetadataParticipant.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 1/20/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct MetadataParticipant: Decodable, CustomStringConvertible {
  let type: String
  let identity: String
  let handle: String?

  public var description: String {
    var responseDesc = ""
    let propertyKeyValues: [String] = [
      "type: \(type)",
      "identity: \(identity)",
      "handle: \(handle ?? "-")"
    ]
    propertyKeyValues.forEach { desc in
      responseDesc.append("\n\t\(desc)")
    }

    return responseDesc
  }

}
