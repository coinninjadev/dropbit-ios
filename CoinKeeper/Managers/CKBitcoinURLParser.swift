//
//  CKBitcoinURLParser.swift
//  DropBit
//
//  Created by Ben Winters on 12/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class CKBitcoinURLParser: CKParser {
  typealias Result = BitcoinURL

  var bitcoinAddressValidator: CompositeValidator = {
    return CompositeValidator<String>(validators: [BitcoinAddressValidator()])
  }()

  /// Checks that BitcoinURL is able to parse the string
  /// and if it includes an address, that the address passes validation
  func parse(_ string: String) throws -> BitcoinURL? {
    if let bitcoinURL = BitcoinURL(string: string), bitcoinURL.components.addressOrPaymentRequestExists {
      if let address = bitcoinURL.components.address {
        try bitcoinAddressValidator.validate(value: address)
      }

      return bitcoinURL

    } else {
      // Re-evaluate string as Bech 32 to throw specific error for display
      do {
        try bitcoinAddressValidator.validate(value: string)
        return nil
      } catch {
        throw error
      }
    }
  }

}
