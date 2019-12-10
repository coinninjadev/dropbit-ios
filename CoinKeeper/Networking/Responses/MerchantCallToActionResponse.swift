//
//  MerchantCallToActionResponse.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum MerchantCallToActionStyle: String {
  case device
  case `default`
  case atm
}

struct MerchantCallToActionResponse: ResponseDecodable {
  let style: String
  let link: String
  let title: String?
  let color: String?

  var actionStyle: MerchantCallToActionStyle {
    return MerchantCallToActionStyle(rawValue: style) ?? .default
  }
}

extension MerchantCallToActionResponse {

  static var sampleJSON: String {
    return "{}"
  }

   static var requiredStringKeys: [KeyPath<MerchantCallToActionResponse, String>] {
    return [\.link, \.style]
   }

   static var optionalStringKeys: [WritableKeyPath<MerchantCallToActionResponse, String?>] { return [] }

}
