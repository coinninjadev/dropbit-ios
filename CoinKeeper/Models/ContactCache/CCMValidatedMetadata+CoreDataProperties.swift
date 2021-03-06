//
//  CCMValidatedMetadata+CoreDataProperties.swift
//  DropBit
//
//  Created by Ben Winters on 2/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CCMValidatedMetadata {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CCMValidatedMetadata> {
    return NSFetchRequest<CCMValidatedMetadata>(entityName: "CCMValidatedMetadata")
  }

  @NSManaged public var countryCode: Int
  @NSManaged public var nationalNumber: String
  @NSManaged public var hashedGlobalNumber: String

  /// If there is more than one CCMPhoneNumber, the user has duplicates in their device contacts.
  /// To-many enables each duplicate to link to this shared CCMValidatedMetadata object.
  @NSManaged public var cachedPhoneNumbers: Set<CCMPhoneNumber>

}
