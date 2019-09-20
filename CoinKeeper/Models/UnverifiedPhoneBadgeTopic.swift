//
//  UnverifiedPhoneBadgeTopic.swift
//  DropBit
//
//  Created by BJ Miller on 11/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData

class UnverifiedPhoneBadgeTopic: BadgeTopic {
  override var badgeTopicType: BadgeTopicType {
    return .unverifiedPhone
  }

  override func badgeStatus(from persistenceManager: PersistenceManagerType, in context: NSManagedObjectContext) -> BadgeTopicStatus {
    return persistenceManager.brokers.user.userIsVerified(in: context) ? [.inactive] : [.actionNeeded]
  }

  override func changesShouldTriggerBadgeUpdate(persistenceManager: PersistenceManagerType, in context: NSManagedObjectContext) -> Bool {
    return contextHasChanges(matchingTypes: PersistenceChangeType.allCases, forEntities: [CKMUser.entity()], in: context)
  }

  private func contextHasChanges(matchingTypes changeTypes: [PersistenceChangeType],
                                 forEntities entities: [NSEntityDescription],
                                 in context: NSManagedObjectContext) -> Bool {
    guard entities.isNotEmpty, changeTypes.isNotEmpty else { return false }

    let relevantEntityNames: [String] = entities.compactMap { $0.managedObjectClassName }

    var relevantInserts = 0
    var relevantUpdates = 0
    var relevantDeletions = 0

    for type in changeTypes {
      switch type {
      case .insert:
        relevantInserts = context.insertedObjects.filter { self.objectMatchesAnyEntity($0, entityNames: relevantEntityNames) }.count
      case .update:
        relevantUpdates = context.persistentUpdatedObjects.filter { self.objectMatchesAnyEntity($0, entityNames: relevantEntityNames) }.count
      case .delete:
        relevantDeletions = context.deletedObjects.filter { self.objectMatchesAnyEntity($0, entityNames: relevantEntityNames) }.count
      }
    }

    let totalChanges = relevantInserts + relevantUpdates + relevantDeletions
    return totalChanges > 0
  }

  private func objectMatchesAnyEntity(_ object: NSManagedObject, entityNames: [String]) -> Bool {
    guard let objectEntityName = object.entity.managedObjectClassName else { return false }
    return entityNames.contains(objectEntityName)
  }
}
