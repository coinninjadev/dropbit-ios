//
//  LightningURL.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct LightningURL {

  let absoluteString: String
  let invoice: String

  static let scheme = "lightning"
  private static let invoicePrefix = "lnbc"

  init?(string: String) {
    let normalizedString = LightningURL.normalizedInputString(string)

    guard let comps = URLComponents(string: normalizedString),
      comps.scheme == LightningURL.scheme
      else { return nil }

    absoluteString = normalizedString
    invoice = comps.path
  }

  private static func normalizedInputString(_ initialString: String) -> String {
    let lowercased = initialString.lowercased()
    if !lowercased.contains(LightningURL.scheme) && lowercased.contains(invoicePrefix) {
      return LightningURL.scheme + ":" + lowercased
    } else {
      return lowercased
    }
  }
}
