//
//  MockPhoneNumberFormatter.swift
//  DropBit
//
//  Created by Ben Winters on 2/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockPhoneNumberFormatter: PhoneNumberFormatterType {

  func string(from phoneNumber: GlobalPhoneNumber) throws -> String {
    return phoneNumber.asE164()
  }

}
