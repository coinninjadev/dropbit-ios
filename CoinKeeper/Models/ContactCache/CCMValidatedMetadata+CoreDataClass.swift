//
//  CCMValidatedMetadata+CoreDataClass.swift
//  DropBit
//
//  Created by Ben Winters on 2/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CCMValidatedMetadata)
public class CCMValidatedMetadata: NSManagedObject {

  public convenience init(phoneNumber: GlobalPhoneNumber, hashedGlobalNumber: String, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.countryCode = phoneNumber.countryCode
    self.nationalNumber = phoneNumber.nationalNumber
    self.hashedGlobalNumber = hashedGlobalNumber
  }

  static func find(withNumber phoneNumber: GlobalPhoneNumber, in context: NSManagedObjectContext) -> CCMValidatedMetadata? {
    let countryPath = #keyPath(CCMValidatedMetadata.countryCode)
    let nationalPath = #keyPath(CCMValidatedMetadata.nationalNumber)
    let countryPredicate = NSPredicate(format: "\(countryPath) == %d", phoneNumber.countryCode)
    let nationalPredicate = NSPredicate(format: "\(nationalPath) == %@", phoneNumber.nationalNumber)
    let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [nationalPredicate, countryPredicate])

    let request: NSFetchRequest<CCMValidatedMetadata> = CCMValidatedMetadata.fetchRequest()
    request.predicate = compoundPredicate
    request.fetchLimit = 1

    do {
      return try context.fetch(request).first
    } catch {
      print(error.localizedDescription)
      return nil
    }
  }


  /// It is possible for the user to have duplicates in their device contacts
  /// that all point to the same CCMValidatedMetadata object. This provides a
  /// consistent displayName in that situation.
  func firstDisplayNameForCachedPhoneNumbers() -> String? {
    let displayNames = cachedPhoneNumber.compactMap { $0.cachedContact?.displayName }
    return displayNames.sorted().first
  }

}
