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
    let updateCountByEntity: [String: Int] = countByEntityDictionary(for: self.persistentUpdatedObjects)
    let deleteCountByEntity: [String: Int] = countByEntityDictionary(for: self.deletedObjects)
    let updatedProperties = self.updatedPropertiesDescription()

    if withLinebreaks {
      return """
      \tInserted:
      \t\t\(insertCountByEntity)
      \tUpdated:
      \t\t\(updateCountByEntity)
      \t\t\(updatedProperties)
      \tDeleted:
      \t\t\(deleteCountByEntity)
      """
    } else {
      return "Inserted: \(insertCountByEntity), Updated: \(updateCountByEntity), Deleted: \(deleteCountByEntity)"
    }
  }

  /// hasChanges returns true if any objects had properties/relationships set on them,
  /// even if the new value is the same as the persisted value.
  /// This only returns true if those "updated" objects have new values that differ from persistence.
  var hasPersistentChanges: Bool {
    return insertedObjects.isNotEmpty || deletedObjects.isNotEmpty || persistentUpdatedObjects.isNotEmpty
  }

  /// Returns objects that have values which do not compare isEqual to the persisted values
  var persistentUpdatedObjects: Set<NSManagedObject> {
    return self.updatedObjects.filter { $0.hasPersistentChangedValues }
  }

  private func countByEntityDictionary(for objectSet: Set<NSManagedObject>) -> [String: Int] {
    return objectSet.reduce(into: [:]) { counts, object in
      guard let entity = object.entity.name else { return }
      counts[entity, default: 0] += 1
    }
  }

  private func updatedPropertiesDescription() -> String {
    let sortedObjects = self.persistentUpdatedObjects.sorted(by: { $0.entity.name ?? "" < $1.entity.name ?? "" })
    let objectDescriptions = sortedObjects.compactMap { object -> String? in
      let changedKeys = object.changedValues().map { $0.key }
      guard changedKeys.isNotEmpty else { return nil }
      let objectType = object.entity.name ?? ""
      let keyValueDescriptions: [String] = changedKeys.map { key in
        return self.propertyDescription(for: object, key: key)
      }
      let joinedPropertyDescriptions = keyValueDescriptions.joined(separator: ", ")
      let objectDesc = "[\(joinedPropertyDescriptions)]"
      return "\(objectType) - \(objectDesc)"
    }
    return objectDescriptions.joined(separator: " \n\t\t")
  }

  private func propertyDescription(for object: NSManagedObject, key: String) -> String {
    var valueDesc = ""
    if let relationship = object.entity.relationshipsByName[key],
      let destinationType = relationship.destinationEntity?.name {
      let destinationDesc = relationship.isToMany ? "Set<\(destinationType)>" : destinationType
      let relationshipDesc = (object.value(forKey: key) == nil) ? "nil (\(destinationDesc))" : "\(destinationDesc)"
      valueDesc = relationshipDesc
    } else {
      valueDesc = object.value(forKey: key).flatMap { String(describing: $0) } ?? "nil"
    }

    return "\(key): \(valueDesc)"
  }

  /// Saves the current context and each parent until changes are saved to the persistent store.
  func saveRecursively(isFirstCall: Bool = true, file: String = #file, function: String = #function, line: Int = #line) throws {
    if isFirstCall {
      // Subsequent recursive saves will show `context.hasChanges == false`,
      // but they still need to be saved to the persistent store, hence only check hasPersistentChanges if isFirstCall
      guard self.hasPersistentChanges else {
        print("No changes to save")
        return
      }

      let changes = self.changesDescription(withLinebreaks: true)
      let contextName = self.name ?? "unknown context"
      log.debug("\nWill save changes in \(contextName): \n\(changes)", file: file, function: function, line: line)
    }

    do {
      try self.save()
    } catch {
      log.contextSaveError(error, file: file, function: function, line: line)
      throw error //rethrow error after logging save error details
    }

    if let parentContext = self.parent {
      try parentContext.performThrowingAndWait {
        try parentContext.saveRecursively(isFirstCall: false)
      }
    }
  }

}
