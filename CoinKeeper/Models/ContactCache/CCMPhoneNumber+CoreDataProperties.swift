//
//  CCMPhoneNumber+CoreDataProperties.swift
//  DropBit
//
//  Created by Ben Winters on 2/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

/// notVerified is both used for identities that have begun registration but not fully verified,
/// as well as for identities that are unknown to the server.
/// The rawValue is used for section order on Contacts screen and must be ascending to match the section order.
@objc public enum UserIdentityVerificationStatus: Int16 {
  case verified = 0
  case notVerified

  /// Turns server response string into enum case that can be persisted
  static func `case`(forString string: String) -> UserIdentityVerificationStatus? {
    switch string {
    case "new",
         "pending":   return .notVerified
    case "verified":  return .verified
    default:          return nil
    }
  }

}

extension CCMPhoneNumber {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CCMPhoneNumber> {
    return NSFetchRequest<CCMPhoneNumber>(entityName: "CCMPhoneNumber")
  }

  @NSManaged public var displayNumber: String

  /// Sanitized version of `CNPhoneNumber.stringValue`
  /// This may or may not include the country code. Can be used for fuzzy matching.
  @NSManaged public var sanitizedOriginalNumber: String

  /// Value is `label` from CNLabeledValue<CNPhoneNumber>
  /// Use this to filter results according to the label constants in Contacts
  /// Use CNContact.localizedString(forKey:) to generate a display string for the phone number type
  @NSManaged public var labelKey: String?

  @NSManaged public var verificationStatus: UserIdentityVerificationStatus

  @NSManaged public var cachedContact: CCMContact?
  @NSManaged public var cachedValidatedMetadata: CCMValidatedMetadata?

}
