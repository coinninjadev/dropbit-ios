//
//  ManagedPhoneNumberInputs.swift
//  DropBit
//
//  Created by Ben Winters on 2/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// The types match CKMPhoneNumber properties so that they can be used for initialization and querying.
public struct ManagedPhoneNumberInputs {
  let countryCode: Int16
  let nationalNumber: Int

  init(countryCode: Int16, nationalNumber: Int) {
    self.countryCode = countryCode
    self.nationalNumber = nationalNumber
  }

  init?(countryCode: Int, nationalNumber: String) {
    guard let codeAsInt16 = Int16(exactly: countryCode),
      let numberAsInt = Int(nationalNumber) else {
        return nil
    }
    self.init(countryCode: codeAsInt16, nationalNumber: numberAsInt)
  }

  init?(phoneNumber: GlobalPhoneNumber) {
    self.init(countryCode: phoneNumber.countryCode, nationalNumber: phoneNumber.sanitizedNationalNumber())
  }

  func asGlobalPhoneNumber() -> GlobalPhoneNumber {
    return GlobalPhoneNumber(countryCode: Int(countryCode), nationalNumber: "\(nationalNumber)")
  }

}
