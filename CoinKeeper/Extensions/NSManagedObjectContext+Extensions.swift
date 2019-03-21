//
//  NSManagedObjectContext+Extensions.swift
//  DropBit
//
//  Created by Ben Winters on 2/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {

  /// - parameter withLinebreaks: true for print, false for os_log
  func changesDescription(withLinebreaks: Bool = false) -> String {
    let insertCountByEntity: [String: Int] = countByEntityDictionary(for: self.insertedObjects)
    let updateCountByEntity: [String: Int] = countByEntityDictionary(for: self.updatedObjects)
    let deleteCountByEntity: [String: Int] = countByEntityDictionary(for: self.deletedObjects)

    if withLinebreaks {
      return """
      \tInserted:
      \t\t\(insertCountByEntity)
      \tUpdated:
      \t\t\(updateCountByEntity)
      \tDeleted:
      \t\t\(deleteCountByEntity)
      """
    } else {
      return "Inserted: \(insertCountByEntity), Updated: \(updateCountByEntity), Deleted: \(deleteCountByEntity)"
    }
  }

  private func countByEntityDictionary(for objectSet: Set<NSManagedObject>) -> [String: Int] {
    return objectSet.reduce(into: [:]) { counts, object in
      guard let entity = object.entity.name else { return }
      counts[entity, default: 0] += 1
    }
  }

  /// Saves the current context until it is saved to the persistent store.
  /// Recursive saves will proceed regardless of whether the current context has changes.
  func saveToDisk() throws {
    if self.hasChanges {
      if parent == nil {
        let changeDesc = self.changesDescription(withLinebreaks: true)
        print("Will save changes to persistent store: \n\(changeDesc)")
      }
      try self.save()
    }

    if let parentContext = self.parent {
      try parentContext.saveToDisk()
    }
  }

}
