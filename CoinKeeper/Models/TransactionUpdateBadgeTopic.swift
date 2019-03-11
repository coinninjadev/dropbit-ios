//
//  TransactionUpdateBadgeTopic.swift
//  DropBit
//
//  Created by BJ Miller on 11/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData

class TransactionUpdateBadgeTopic: BadgeTopic {

  override var badgeTopicType: BadgeTopicType {
    return .transactionUpdates
  }

  override func badgeStatus(from persistenceManager: PersistenceManagerType, in context: NSManagedObjectContext) -> BadgeTopicStatus {
    return persistenceManager.bool(for: .unseenTransactionChangesExist) ? [.unseen] : [.inactive]
  }

  override func changesShouldTriggerBadgeUpdate(persistenceManager: PersistenceManagerType, in context: NSManagedObjectContext) -> Bool {
    if contextChangesShouldTriggerNewTransactionBadge(in: context) {
      persistenceManager.set(true, for: .unseenTransactionChangesExist)
      return true
    } else {
      return false
    }
  }

  private func contextChangesShouldTriggerNewTransactionBadge(in context: NSManagedObjectContext) -> Bool {
    let insertedTransactions = context.insertedObjects.compactMap { $0 as? CKMTransaction }
    let incomingTransactions = insertedTransactions.filter { $0.isIncoming }
    return incomingTransactions.isNotEmpty
  }
}
