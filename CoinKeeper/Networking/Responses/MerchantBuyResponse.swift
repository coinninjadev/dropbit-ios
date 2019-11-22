//
//  MerchantBuyResponse.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct MerchantBuyResponse: ResponseDecodable {
  let buy: [MerchantResponse]
}

extension MerchantBuyResponse {

  static var sampleJSON: String {
    return "{}"
  }

   static var requiredStringKeys: [KeyPath<MerchantBuyResponse, String>] {
    return []
   }

   static var optionalStringKeys: [WritableKeyPath<MerchantBuyResponse, String?>] { return [] }

}
