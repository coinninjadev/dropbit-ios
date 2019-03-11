//
//  WordsNotBackedUpBadgeTopic.swift
//  DropBit
//
//  Created by BJ Miller on 11/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData

class WordsNotBackedUpBadgeTopic: BadgeTopic {
  override var badgeTopicType: BadgeTopicType {
    return .wordsNotBackedUp
  }

  override func badgeStatus(from persistenceManager: PersistenceManagerType, in context: NSManagedObjectContext) -> BadgeTopicStatus {
    guard let backedUp = persistenceManager.keychainManager.bool(for: .walletWordsBackedUp) else { return [.unseen] }
    return backedUp ? [.inactive] : [.actionNeeded]
  }

  override func changesShouldTriggerBadgeUpdate(persistenceManager: PersistenceManagerType, in context: NSManagedObjectContext) -> Bool {
    guard let backedUp = persistenceManager.keychainManager.bool(for: .walletWordsBackedUp) else { return true }
    return !backedUp
  }
}
