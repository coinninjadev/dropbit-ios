//
//  MerchantConfigurationResponse.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct MerchantConfigurationResponse: ResponseDecodable {
  let updatedAt: Date?
  let config: MerchantBuyResponse
}

extension MerchantConfigurationResponse {

  static var sampleJSON: String {
    return "{}"
  }

   static var requiredStringKeys: [KeyPath<MerchantConfigurationResponse, String>] {
    return []
   }

   static var optionalStringKeys: [WritableKeyPath<MerchantConfigurationResponse, String?>] { return [] }

}
