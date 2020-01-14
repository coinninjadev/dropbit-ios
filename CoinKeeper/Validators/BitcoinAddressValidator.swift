//
//  BitcoinAddressValidator.swift
//  DropBit
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Cnlib

enum BitcoinAddressValidatorError: ValidatorErrorType {
  case isInvalidBitcoinAddress
  case notBase58CheckValid
  case notBech32Valid

  var displayMessage: String {
    switch self {
    case .isInvalidBitcoinAddress:  return "Invalid bitcoin address."
    case .notBase58CheckValid:      return "Address is not properly Base58Check encoded."
    case .notBech32Valid:
      return """
      Address is not properly Bech32 encoded.
      Please check that you have the correct address and try again.
      """.removingMultilineLineBreaks()
    }
  }

}

class BitcoinAddressValidator: ValidatorType<String> {

  override func validate(value: String) throws {
    guard value.isNotEmpty else { throw BitcoinAddressValidatorError.isInvalidBitcoinAddress }
    guard value != "1111111111111111111114oLvT2" else { throw BitcoinAddressValidatorError.isInvalidBitcoinAddress }
    var error: BitcoinAddressValidatorError?
    let mainNet = "bc"
    let regTest = "bcrt"
    let possibleHRPs = [mainNet, regTest]
    let addressStartsWithHRP = possibleHRPs.contains(where: { value.lowercased().starts(with: $0) })

    var errorPtr: NSError?
    if addressStartsWithHRP {
      let address = value.lowercased()
      if !CNBCnlibAddressIsValidSegwitAddress(address, &errorPtr) {
        error = .notBech32Valid
      }
    } else {
      let valid = CNBCnlibAddressIsBase58CheckEncoded(value, &errorPtr)
      if !valid, let err = errorPtr {
        log.error(err, message: "Address \(value) failed base58check decoding.")
        error = .notBase58CheckValid
      }
    }

    if let existingError = error {
      throw existingError
    }
  }
}
