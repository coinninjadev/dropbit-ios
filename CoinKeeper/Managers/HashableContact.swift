//
//  HashableContact.swift
//  DropBit
//
//  Created by Ben Winters on 2/27/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Contacts

struct HashableContact: Hashable {

  let identifier: String
  let displayName: String
  let phoneNumbers: Set<HashablePhoneNumber>

  init(cnContact: CNContact, formatter: CNContactFormatter) {
    self.identifier = cnContact.identifier
    self.displayName = formatter.string(from: cnContact) ?? ""
    let hashableNumbers = cnContact.phoneNumbers.map { HashablePhoneNumber(labeledNumber: $0) }
    self.phoneNumbers = Set(hashableNumbers)
  }

  init(ccmContact: CCMContact) {
    self.identifier = ccmContact.cnContactIdentifier
    self.displayName = ccmContact.displayName
    let hashableNumbers = ccmContact.cachedPhoneNumbers.map { HashablePhoneNumber(managedNumber: $0) }
    self.phoneNumbers = Set(hashableNumbers)
  }

}

struct HashablePhoneNumber: Hashable {

  let labelKey: String
  let originalSanitizedNumber: String

  init(labeledNumber: CNLabeledValue<CNPhoneNumber>) {
    self.labelKey = labeledNumber.label ?? ""
    self.originalSanitizedNumber = labeledNumber.value.stringValue.droppingExtensions().removingNonDecimalCharacters()
  }

  init(managedNumber: CCMPhoneNumber) {
    self.labelKey = managedNumber.labelKey ?? ""
    self.originalSanitizedNumber = managedNumber.sanitizedOriginalNumber
  }

}
