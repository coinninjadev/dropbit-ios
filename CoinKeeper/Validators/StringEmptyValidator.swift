//
//  StringValidator.swift
//  DropBit
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum StringEmptyValidatorError: ValidatorErrorType {
  case isEmpty

  var displayMessage: String {
    switch self {
    case .isEmpty: return "String is empty."
    }
  }

}

class StringEmptyValidator: ValidatorType<String> {

  override func validate(value: String) throws {
    if value.isEmpty {
      throw StringEmptyValidatorError.isEmpty
    }
  }
}
