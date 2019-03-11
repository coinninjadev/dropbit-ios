//
//  StringValidator.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum StringEmptyValidatorError: ValidatorTypeError {
  case isEmpty

  var debugMessage: String {
    switch self {
    case .isEmpty: return "Value is empty."
    }
  }

  var displayMessage: String? {
    return nil
  }

}

class StringEmptyValidator: ValidatorType<String> {

  override func validate(value: String) throws {
    if value.isEmpty {
      throw StringEmptyValidatorError.isEmpty
    }
  }
}
