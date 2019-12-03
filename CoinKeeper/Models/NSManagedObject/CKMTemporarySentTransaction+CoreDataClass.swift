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

  static func findAllActiveOnChain(in context: NSManagedObjectContext) -> [CKMTemporarySentTransaction] {
    let fetchRequest: NSFetchRequest<CKMTemporarySentTransaction> = CKMTemporarySentTransaction.fetchRequest()

    let hasOnChainTxPredicate = CKPredicate.TemporarySentTransaction.withOnChainTransaction()

    let notInactiveInvitationPredicate = CKPredicate.TemporarySentTransaction.withoutInactiveInvitation()
    let txNotFailedPredicate = CKPredicate.TemporarySentTransaction.broadcastFailed(is: false)
    let andPredicates = [hasOnChainTxPredicate, notInactiveInvitationPredicate, txNotFailedPredicate]
    fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: andPredicates)

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

  func copyForLightning() -> CKMTemporarySentTransaction? {
    guard let context = managedObjectContext else { return nil }
    let newTempSentTx = CKMTemporarySentTransaction(insertInto: context)
    newTempSentTx.createdAt = self.createdAt
    newTempSentTx.amount = self.amount
    newTempSentTx.feeAmount = self.feeAmount
    newTempSentTx.txid = self.txid
    return newTempSentTx
  }

}
