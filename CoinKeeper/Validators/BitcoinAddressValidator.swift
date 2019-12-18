//
//  BitcoinAddressValidator.swift
//  DropBit
//
//  Created by Mitchell on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Cnlib

enum BitcoinAddressValidatorError: ValidatorTypeError {
  case isInvalidBitcoinAddress
  case notBase58CheckValid
  case notBech32Valid

  var debugMessage: String {
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

  var displayMessage: String? {
    return debugMessage
  }

}

class BitcoinAddressValidator: ValidatorType<String> {

  override func validate(value: String) throws {
    guard value.isNotEmpty else { throw BitcoinAddressValidatorError.isInvalidBitcoinAddress }
    guard value != "1111111111111111111114oLvT2" else { throw BitcoinAddressValidatorError.isInvalidBitcoinAddress }
    let address = value.lowercased()
    var error: BitcoinAddressValidatorError?
    let mainNet = "bc"
    let regTest = "bcrt"
    let possibleHRPs = [mainNet, regTest]
    let addressStartsWithHRP = possibleHRPs.contains(where: { address.starts(with: $0) })

    let errorPtr = NSErrorPointer(nilLiteral: ())
    if addressStartsWithHRP {
      if !CNBCnlibAddressIsValidSegwitAddress(address, nil, errorPtr), let err = errorPtr?.pointee {
        log.error(err, message: "\(address) is not a valid segwit address")
        error = .notBech32Valid
      }
    } else {
      if !CNBCnlibAddressIsBase58CheckEncoded(address, nil, errorPtr), let err = errorPtr?.pointee {
        log.error(err, message: "\(address) is not a valid base58check encoded address")
        error = .notBase58CheckValid
      }
    }

    if let existingError = error {
      throw existingError
    }
  }
}
