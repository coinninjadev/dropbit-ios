//
//  GlobalPhoneNumber.swift
//  DropBit
//
//  Created by Ben Winters on 2/11/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit

/// A simple struct for passing around phone number details. Values are not necessarily valid or complete.
public struct GlobalPhoneNumber: Codable, CustomStringConvertible {
  var countryCode: Int
  var nationalNumber: String

  /// This may not always be available, but can be useful to pass around when known
  var regionCode: String?

  init(countryCode: Int, nationalNumber: String, regionCode: String? = nil) {
    self.countryCode = countryCode
    self.nationalNumber = nationalNumber
    self.regionCode = regionCode
  }

  init(parsedNumber: PhoneNumber, regionCode: String? = nil) {
    self.countryCode = Int(parsedNumber.countryCode)
    self.nationalNumber = "\(parsedNumber.nationalNumber)"
    self.regionCode = regionCode ?? parsedNumber.regionID
  }

  func sanitizedNationalNumber() -> String {
    let invalidCharacters = CharacterSet.decimalDigits.inverted
    return nationalNumber.components(separatedBy: invalidCharacters).joined()
  }

  func sanitizedGlobalNumber() -> String {
    return "\(countryCode)" + sanitizedNationalNumber()
  }

  func asE164() -> String {
    return "+\(countryCode)" + sanitizedNationalNumber()
  }

  public var description: String {
    return "+\(countryCode) \(nationalNumber)"
  }

}
