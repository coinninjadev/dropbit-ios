//
//  MerchantResponse.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

struct MerchantResponse: ResponseDecodable {

  let image: String
  let tooltip: String?
  let attributes: [MerchantAttributeResponse]
  let cta: MerchantCallToActionResponse
}

extension MerchantResponse {

  static var sampleJSON: String {
    return "{}"
  }

   static var requiredStringKeys: [KeyPath<MerchantResponse, String>] {
     return [\.image]
   }

   static var optionalStringKeys: [WritableKeyPath<MerchantResponse, String?>] { return [] }

}
