//
//  CCMContact+CoreDataClass.swift
//  DropBit
//
//  Created by Ben Winters on 2/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import Contacts

@objc(CCMContact)
public class CCMContact: NSManagedObject {

  /// Formatter handles the ordering of family and given names according to the locale.
  /// Returns nil for contacts with an empty display name.
  public convenience init?(cnContact: CNContact,
                           formatter: CNContactFormatter,
                           insertInto context: NSManagedObjectContext) {
    guard let displayName = formatter.string(from: cnContact), displayName.isNotEmpty else { return nil }
    self.init(insertInto: context)
    self.cnContactIdentifier = cnContact.identifier
    self.displayName = displayName
    self.givenName = cnContact.givenName.asNilIfEmpty()
    self.familyName = cnContact.familyName.asNilIfEmpty()
  }

  static func findAll(in context: NSManagedObjectContext) throws -> [CCMContact] {
    let fetchRequest: NSFetchRequest<CCMContact> = CCMContact.fetchRequest()
    return try context.fetch(fetchRequest)
  }

}
