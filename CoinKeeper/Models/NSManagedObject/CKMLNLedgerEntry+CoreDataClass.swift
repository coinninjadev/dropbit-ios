//
//  CKMLNLedgerEntry+CoreDataClass.swift
//  
//
//  Created by Ben Winters on 8/9/19.
//
//

import Foundation
import CoreData

@objc(CKMLNLedgerEntry)
public class CKMLNLedgerEntry: NSManagedObject {

  static func updateOrCreate(with result: LNTransactionResult,
                             forWallet wallet: CKMWallet,
                             in context: NSManagedObjectContext) {
    let entry = findOrCreate(with: result.cleanedId, wallet: wallet, createdAt: result.createdAt, in: context)
    entry.accountId = result.accountId
    entry.createdAt = result.createdAt
    entry.updatedAt = result.updatedAt
    entry.expiresAt = result.expiresAt
    entry.status = CKMLNTransactionStatus(status: result.status)
    entry.type = CKMLNTransactionType(type: result.type)
    entry.direction = CKMLNTransactionDirection(direction: result.direction)
    entry.value = result.value
    entry.networkFee = result.networkFee
    entry.processingFee = result.processingFee
    entry.request = result.request
    entry.error = result.error

    // User may have added local memo
    if let resultMemo = result.memo, entry.memo == nil {
      entry.memo = resultMemo
    }

  }

  static func findOrCreate(with id: String, wallet: CKMWallet, createdAt: Date, in context: NSManagedObjectContext) -> CKMLNLedgerEntry {
    if let foundEntry = find(with: id, wallet: wallet, in: context) {
      return foundEntry
    } else {
      let newEntry = CKMLNLedgerEntry(insertInto: context)
      newEntry.id = id
      newEntry.walletEntry = CKMWalletEntry(wallet: wallet, sortDate: createdAt, insertInto: context)
      return newEntry
    }
  }

  static func find(with id: String, wallet: CKMWallet?, in context: NSManagedObjectContext) -> CKMLNLedgerEntry? {
    let idPath = #keyPath(CKMLNLedgerEntry.id)
    let idPredicate = NSPredicate(format: "\(idPath) == %@", id)
    var predicates = [idPredicate]

    if let wallet = wallet {
      let walletPath = #keyPath(CKMLNLedgerEntry.walletEntry.wallet)
      let walletPredicate = NSPredicate(format: "\(walletPath) == %@", wallet)
      predicates.append(walletPredicate)
    }

    let fetchRequest = NSFetchRequest<CKMLNLedgerEntry>(entityName: entityName())
    fetchRequest.fetchLimit = 1
    fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)

    do {
      return try context.fetch(fetchRequest).first
    } catch {
      log.error(error, message: "Failed to fetch ledger entry for id: \(id)")
      return nil
    }
  }
}
