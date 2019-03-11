//
//  MockContactCacheManager.swift
//  DropBit
//
//  Created by Ben Winters on 2/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation
import CoreData
import Contacts

class MockContactCacheManager: ContactCacheManagerType {

  var viewContext: NSManagedObjectContext {
    return NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
  }

  func createChildBackgroundContext() -> NSManagedObjectContext {
    return NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
  }

  func createPhoneNumberFetchedResultsController() -> NSFetchedResultsController<CCMPhoneNumber> {
    return NSFetchedResultsController<CCMPhoneNumber>()
  }

  func predicate(forSearch searchText: String) -> NSPredicate {
    return NSPredicate(value: true)
  }

  func allValidatedMetadata(in context: NSManagedObjectContext) throws -> [CCMValidatedMetadata] {
    return []
  }

  func allCachedContacts(in context: NSManagedObjectContext) throws -> [CCMContact] {
    return []
  }

  func phoneNumberCount(in context: NSManagedObjectContext) throws -> Int {
    return 0
  }

  func deleteSystemContactData(in context: NSManagedObjectContext) throws { }

  func persistContacts(_ contacts: [CNContact],
                       inputs: CachedPhoneNumberDependencies,
                       in context: NSManagedObjectContext) throws { }

}
