//
//  URLRequest+Helpers.swift
//  DropBit
//
//  Created by BJ Miller on 10/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension URLRequest {
  mutating func addValue(_ value: String, forCNHeaderField field: CNHeaderParameter) {
    self.addValue(value, forHTTPHeaderField: field.fieldName)
  }

  mutating func addValue<T: RawRepresentable>(_ value: T, forCNHeaderField field: CNHeaderParameter) where T.RawValue == String {
    self.addValue(value.rawValue, forHTTPHeaderField: field.fieldName)
  }

  func value(forCNHeaderParameter parameter: CNHeaderParameter) -> String? {
    return self.value(forHTTPHeaderField: parameter.fieldName)
  }
}
