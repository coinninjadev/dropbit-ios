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

  private let kit: PhoneNumberKit
  private let format: PhoneNumberFormat

  init(kit: PhoneNumberKit, format: PhoneNumberFormat) {
    self.kit = kit
    self.format = format
  }

  func string(from phoneNumber: GlobalPhoneNumber) throws -> String {
    let parsedNumber = try kit.parse(phoneNumber.asE164())
    return kit.format(parsedNumber, toType: self.format)
  }

}
