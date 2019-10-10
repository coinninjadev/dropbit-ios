//
//  DerivativePathResponse.swift
//  DropBit
//
//  Created by BJ Miller on 6/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

struct DerivativePathResponse: Decodable {
  let purpose: Int
  let coin: Int
  let account: Int
  let change: Int
  let index: Int
}

extension DerivativePathResponse {

  static var sampleReceiveJSON: String {
    return """
    {
    "purpose": 84,
    "coin": 0,
    "account": 0,
    "change": 0,
    "index": 5
    }
    """
  }

  static var sampleChangeJSON: String {
    return """
    {
    "purpose": 84,
    "coin": 0,
    "account": 0,
    "change": 1,
    "index": 5
    }
    """
  }

  var isChangeAddress: Bool {
    return change == CKMDerivativePath.changeIsChangeValue
  }
}

extension DerivativePathResponse {
  init(derivativePath: CNBDerivationPath) {
    self.purpose = Int(derivativePath.purpose.rawValue)
    self.coin = Int(derivativePath.coinType.rawValue)
    self.account = Int(derivativePath.account)
    self.change = Int(derivativePath.change)
    self.index = Int(derivativePath.index)
  }
}
