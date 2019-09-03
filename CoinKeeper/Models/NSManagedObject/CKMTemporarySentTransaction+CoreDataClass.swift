//
//  CKMTemporarySentTransaction+CoreDataClass.swift
//  DropBit
//
//  Created by BJ Miller on 6/1/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CKMTemporarySentTransaction)
public class CKMTemporarySentTransaction: NSManagedObject {

  public override func awakeFromInsert() {
    super.awakeFromInsert()
    setPrimitiveValue(Date(), forKey: #keyPath(CKMTemporarySentTransaction.createdAt))
    setPrimitiveValue(false, forKey: #keyPath(CKMTemporarySentTransaction.isSentToSelf))
  }

  var totalAmount: Int {
    let effectiveAmount = isSentToSelf ? 0 : amount
    return effectiveAmount + feeAmount
  }

  static func findAll(in context: NSManagedObjectContext) -> [CKMTemporarySentTransaction] {
    let fetchRequest: NSFetchRequest<CKMTemporarySentTransaction> = CKMTemporarySentTransaction.fetchRequest()

    return fetchTempTransactions(from: fetchRequest, in: context)
  }

  static func findAllActive(in context: NSManagedObjectContext) -> [CKMTemporarySentTransaction] {
    let fetchRequest: NSFetchRequest<CKMTemporarySentTransaction> = CKMTemporarySentTransaction.fetchRequest()

    // Doesn't have an inactive invitation
    let inactiveInvitationPredicate = CKPredicate.TemporarySentTransaction.withInactiveInvitation()
    let notInactiveInvitationPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: inactiveInvitationPredicate)

    // Broadcast not detected as failed
    let txNotFailedPredicate = CKPredicate.TemporarySentTransaction.broadcastFailed(is: false)
    fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [notInactiveInvitationPredicate, txNotFailedPredicate])

    return fetchTempTransactions(from: fetchRequest, in: context)
  }

  private static func fetchTempTransactions(from fetchRequest: NSFetchRequest<CKMTemporarySentTransaction>,
                                            in context: NSManagedObjectContext) -> [CKMTemporarySentTransaction] {
    var result: [CKMTemporarySentTransaction] = []
    context.performAndWait {
      do {
        result = try context.fetch(fetchRequest)
      } catch {
        result = []
      }
    }
    return result
  }
}
