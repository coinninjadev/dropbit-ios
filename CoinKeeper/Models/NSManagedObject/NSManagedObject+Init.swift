//
//  NSManagedObject+Init.swift
//  DropBit
//
//  Created by BJ Miller on 4/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData

extension NSManagedObject {

  static func entityName() -> String {
    return String(describing: self)
  }

  static func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
    return NSEntityDescription.entity(forEntityName: entityName(), in: context)!
  }

  public convenience init(insertInto context: NSManagedObjectContext) {
    self.init(entity: type(of: self).entityDescription(in: context), insertInto: context)
  }

}

extension NSManagedObject {

  /// This doesn't use batch delete so that the change can be observed through NSManagedObjectContextWillSave notification
  static func deleteAll(in context: NSManagedObjectContext) {
    guard let entityName = entityDescription(in: context).name else { return }
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

    context.performAndWait {
      do {
        guard let results = try context.fetch(request) as? [NSManagedObject] else {
          return
        }
        results.forEach({ context.delete($0) })

      } catch {
        log.error(error, message: "Failed to perform batch transaction delete")
        assertionFailure("Failed to perform batch transaction delete: \(error)")
      }
    }
  }

}
