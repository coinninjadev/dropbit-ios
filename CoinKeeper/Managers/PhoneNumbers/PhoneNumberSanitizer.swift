//
//  PhoneNumberSanitizer.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/31/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Contacts

struct PhoneNumberSanitizer {

  private var phoneNumber: String
  private var hashManager: HashingManager = HashingManager()

  init(phoneNumber: CNPhoneNumber) {
    self.phoneNumber = phoneNumber.stringValue
  }

  init(phoneNumberString: String) {
    self.phoneNumber = phoneNumberString
  }

  func sanitize() -> String {
    var rawPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

    if rawPhoneNumber.count == 10 {
      rawPhoneNumber = "1" + rawPhoneNumber
    }

    return rawPhoneNumber
  }

  func sanitizeWithoutCountryCode() -> String {
    var phoneNumber = sanitize()
    guard !phoneNumber.isEmpty else { return "" }

    phoneNumber.remove(at: phoneNumber.startIndex)
    return phoneNumber
  }

  func hash() -> String {
    if let salt = keyDerivation.salt.data(using: .utf8) {
      return hashManager.pbkdf2SHA256(password: sanitize(), salt: salt, keyByteCount: 32, rounds: keyDerivation.iterations)
    }

    return ""
  }

}
