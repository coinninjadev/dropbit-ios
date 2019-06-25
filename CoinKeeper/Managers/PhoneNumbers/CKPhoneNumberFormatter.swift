//
//  PhoneNumberFormatter.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit

protocol PhoneNumberFormatterType: AnyObject {
  func string(from phoneNumber: GlobalPhoneNumber) throws -> String
}

class CKPhoneNumberFormatter: PhoneNumberFormatterType {

  private let format: PhoneNumberFormat

  init(format: PhoneNumberFormat) {
    self.format = format
  }

  func string(from phoneNumber: GlobalPhoneNumber) throws -> String {
    let parsedNumber = try phoneNumberKit.parse(phoneNumber.asE164())
    return phoneNumberKit.format(parsedNumber, toType: self.format)
  }

}
