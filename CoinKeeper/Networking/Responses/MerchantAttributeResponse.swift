//
//  MerchantAttributeResponse.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

enum MerchantAttributeResponseType: String {
  case positive
  case negative
}

struct MerchantAttributeResponse: ResponseDecodable {

  let type: String
  let description: String
  var link: String?

  var merchantType: MerchantAttributeResponseType {
    return MerchantAttributeResponseType(rawValue: type) ?? .positive
  }

  var image: UIImage {
    switch merchantType {
    case .positive:
      return UIImage(imageLiteralResourceName: "checkmarkGreen")
    case .negative:
      return UIImage(imageLiteralResourceName: "close")
    }
  }
}

extension MerchantAttributeResponse {

  static var sampleJSON: String {
    return "{}"
  }

   static var requiredStringKeys: [KeyPath<MerchantAttributeResponse, String>] {
     return [\.description]
   }

   static var optionalStringKeys: [WritableKeyPath<MerchantAttributeResponse, String?>] { return [] }

}
