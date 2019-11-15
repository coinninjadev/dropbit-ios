//
//  BuyMerchantResponse.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

enum BuyMerchantAttributeType: String {
  case positive
  case negative
}

struct BuyMerchantAttribute {

  let type: BuyMerchantAttributeType
  let description: String
  var link: String? = nil

  static var sampleJSON: String { return "" }
  static var requiredStringKeys: [KeyPath<BuyMerchantAttribute, String>] { return [\.description] }
  static var optionalStringKeys: [WritableKeyPath<BuyMerchantAttribute, String?>] { return [] }

  var image: UIImage {
    switch type {
    case .positive:
      return UIImage(imageLiteralResourceName: "checkmarkGreen")
    case .negative:
      return UIImage(imageLiteralResourceName: "close")
    }
  }
}

enum BuyMerchantBuyType: String {
  case device
  case `default`
  case atm
}

struct BuyMerchantResponse {

  let image: UIImage
  let tooltipUrl: String?
  let attributes: [BuyMerchantAttribute]
  let actionType: String
  let actionUrl: String

  var buyType: BuyMerchantBuyType {
    return BuyMerchantBuyType(rawValue: actionType) ?? .default
  }

  static var sampleJSON: String {
    return "{}"
  }

  static var requiredStringKeys: [KeyPath<BuyMerchantResponse, String>] {
    return [\.actionType, \.actionUrl]
  }

  static var optionalStringKeys: [WritableKeyPath<BuyMerchantResponse, String?>] { return [] }

}
