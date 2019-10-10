//
//  WalletAddressesElasticQuery.swift
//  DropBit
//
//  Created by Ben Winters on 1/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class WalletAddressesElasticQuery: ElasticQuery {

  let addressPubkey = true
  let addressType: String

  init(identityHashes: [String], addressType: WalletAddressType) {
    self.addressType = addressType.rawValue
    let terms = ElasticTerms.object(withIdentityHashes: identityHashes)
    super.init(range: nil, script: nil, term: nil, terms: terms)
  }

  private enum CodingKeys: String, CodingKey {
    case addressPubkey, addressType
  }

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.addressPubkey, forKey: .addressPubkey)
    try container.encode(self.addressType, forKey: .addressType)
  }

}
