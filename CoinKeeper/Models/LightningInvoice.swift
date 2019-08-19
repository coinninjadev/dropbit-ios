//
//  LightningInvoice.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct LightningInvoice {

  var absoluteString: String

  init?(string: String) {
    guard string.starts(with: "lnbc") else { return nil }
    absoluteString = string
  }
}
