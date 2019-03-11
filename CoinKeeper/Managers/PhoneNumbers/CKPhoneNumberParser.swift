//
//  CKPhoneNumberParser.swift
//  DropBit
//
//  Created by Ben Winters on 12/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit

class CKPhoneNumberParser: CKParser {
  typealias Result = GlobalPhoneNumber

  let kit: PhoneNumberKit

  init(kit: PhoneNumberKit) {
    self.kit = kit
  }

  func parse(_ string: String) throws -> GlobalPhoneNumber? {
    let parsedNumber = try? kit.parse(string)
    return parsedNumber.map { GlobalPhoneNumber(parsedNumber: $0) }
  }

}
