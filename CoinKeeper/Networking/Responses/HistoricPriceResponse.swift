//
//  HistoricPriceResponse.swift
//  DropBit
//
//  Created by Mitch on 10/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct HistoricPriceResponse: ResponseDecodable {

}

extension HistoricPriceResponse {
  
  static var sampleJSON: String { return "" }
  
  static var requiredStringKeys: [KeyPath<HistoricPriceResponse, String>] { return [] }
  
  static var optionalStringKeys: [WritableKeyPath<HistoricPriceResponse, String?>] { return [] }
  
}
