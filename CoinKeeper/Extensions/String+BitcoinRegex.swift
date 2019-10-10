//
//  String+BitcoinRegex.swift
//  DropBit
//
//  Created by Mitchell Malleo on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

extension String {

  func isValidBitcoinAddress() -> Bool {
    do {
      try BitcoinAddressValidator().validate(value: self)
      return true
    } catch {
      return false
    }
  }

}
