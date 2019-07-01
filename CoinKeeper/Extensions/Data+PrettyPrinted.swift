//
//  Data+PrettyPrinted.swift
//  DropBit
//
//  Created by BJ Miller on 6/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension Data {
  func prettyPrinted() -> String {
    do {
      let dataAsJSON = try JSONSerialization.jsonObject(with: self, options: .allowFragments)
      let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
      return String(data: prettyData, encoding: .utf8) ?? "-"
    } catch {
      return String(data: self, encoding: .utf8) ?? "-"
    }
  }
}
