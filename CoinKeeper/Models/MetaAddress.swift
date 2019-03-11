//
//  MetaAddress.swift
//  DropBit
//
//  Created by Ben Winters on 1/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

public struct MetaAddress {
  let address: String
  let addressPubKey: String

  init(address: String, addressPubKey: String) {
    self.address = address
    self.addressPubKey = addressPubKey
  }

  init?(cnbMetaAddress: CNBMetaAddress) {
    guard let pubKey = cnbMetaAddress.uncompressedPublicKey else { return nil }
    self.init(address: cnbMetaAddress.address, addressPubKey: pubKey)
  }

}
