//
//  ConfigResponseItems.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct FeatureConfigResponse: Codable {
  let enabled: Bool
}

struct ConfigResponseItems: ResponseDecodable {
  let buy: [MerchantResponse]
  let referral: FeatureConfigResponse?
}

extension ConfigResponseItems {

  static var sampleJSON: String {
    return "{}"
  }

   static var requiredStringKeys: [KeyPath<ConfigResponseItems, String>] {
    return []
   }

   static var optionalStringKeys: [WritableKeyPath<ConfigResponseItems, String?>] { return [] }

}
