//
//  CCMPhoneNumber+CoreDataClass.swift
//  DropBit
//
//  Created by Ben Winters on 2/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CCMPhoneNumber)
public class CCMPhoneNumber: NSManagedObject {

  public convenience init(formattedNumber: String,
                          sanitizedOriginal: String,
                          labelKey: String?,
                          insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.displayNumber = formattedNumber
    self.sanitizedOriginalNumber = sanitizedOriginal
    self.labelKey = labelKey
    self.verificationStatus = .notVerified
  }

  /// Prevents Core Data from reporting objects as updated just because the property was set
  func setStatusIfDifferent(_ newStatus: PhoneNumberVerificationStatus) {
    if self.verificationStatus != newStatus {
      self.verificationStatus = newStatus
    }
  }

}
