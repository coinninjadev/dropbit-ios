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

  private func countByEntityDictionary(for objectSet: Set<NSManagedObject>) -> [String: Int] {
    return objectSet.reduce(into: [:]) { counts, object in
      guard let entity = object.entity.name else { return }
      counts[entity, default: 0] += 1
    }
  }

  private func updatedPropertiesDescription() -> String {
    var result = ""
    let sortedObjects = self.updatedObjects.sorted(by: { $0.entity.name ?? "" < $1.entity.name ?? "" })
    for object in sortedObjects {
      let objectType = object.entity.name ?? ""
      let keyValueDescriptions: [String] = object.changedValues().keys.map { key in
        return self.propertyDescription(for: object, key: key)
      }
      let joinedPropertyDescriptions = keyValueDescriptions.joined(separator: ", ")
      let objectDesc = "[\(joinedPropertyDescriptions)]"
      result += "\(objectType) - \(objectDesc) \n\t\t"
    }
    return result
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
  /// Recursive saves will proceed only if the current context has changes
  /// to avoid interfering with the state of parent contexts.
  func saveRecursively() throws {
    guard self.hasChanges else { return }
    let preSaveChanges = self.changesDescription(withLinebreaks: true)

    try self.save()

    if let parentContext = self.parent {
      try parentContext.performThrowingAndWait {
        try parentContext.saveRecursively()
      }
    } else {
      log.debug("Did save changes to persistent store: \n\(preSaveChanges)")
    }
  }

}
