//
//  BadgeTopic.swift
//  DropBit
//
//  Created by BJ Miller on 11/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

enum BadgeTopicType: String {
  case transactionUpdates
  case unverifiedPhone
  case wordsNotBackedUp
}

/// Abstract base class for badge topic types, intended for subclasses to encapsulate behavior
///  and allow BadgeManager to be closed for modification.
class BadgeTopic {
  var badgeTopicStatus: BadgeTopicStatus

  init() {
    self.badgeTopicStatus = [.inactive]
  }

  static let notificationKeyPrefix = "BadgeTopic_"

  var notificationKey: String {
    return BadgeTopic.notificationKeyPrefix + badgeTopicType.rawValue
  }

  var badgeTopicType: BadgeTopicType {
    fatalError("Must override")
  }

  func badgeStatus(from persistenceManager: PersistenceManagerType, in context: NSManagedObjectContext) -> BadgeTopicStatus {
    fatalError("Must override")
  }

  func changesShouldTriggerBadgeUpdate(persistenceManager: PersistenceManagerType, in context: NSManagedObjectContext) -> Bool {
    fatalError("Must override")
  }

  func badgeInfo() -> BadgeInfo {
    return [badgeTopicType: badgeTopicStatus]
  }
}

extension BadgeTopic: Hashable {
  static func == (lhs: BadgeTopic, rhs: BadgeTopic) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(badgeTopicType)
  }
}
