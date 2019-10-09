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

  @discardableResult
  static func updateOrCreate(with result: LNTransactionResult,
                             forWallet wallet: CKMWallet,
                             in context: NSManagedObjectContext) -> CKMLNLedgerEntry {
    let entry = findOrCreate(with: result.cleanedId, wallet: wallet, createdAt: result.createdAt, in: context)
    configure(entry, with: result)
    return entry
  }

  static func findOrCreate(with id: String, wallet: CKMWallet, createdAt: Date, in context: NSManagedObjectContext) -> CKMLNLedgerEntry {
    if let foundEntry = find(withId: id, wallet: wallet, in: context) {
      return foundEntry
    } else {
      let newEntry = CKMLNLedgerEntry(insertInto: context)
      newEntry.id = id
      newEntry.walletEntry = CKMWalletEntry(wallet: wallet, sortDate: createdAt, insertInto: context)
      return newEntry
    }
  }

  static func create(with response: LNTransactionResult, in context: NSManagedObjectContext) -> CKMLNLedgerEntry {
    let newEntry = CKMLNLedgerEntry(insertInto: context)
    configure(newEntry, with: response)

    return newEntry
  }

  private static func configure(_ entry: CKMLNLedgerEntry, with result: LNTransactionResult) {
    entry.id = result.cleanedId
    entry.accountId = result.accountId
    entry.walletEntry?.sortDate = result.createdAt
    entry.createdAt = result.createdAt
    entry.updatedAt = result.updatedAt
    entry.expiresAt = result.expiresAt
    entry.status = CKMLNTransactionStatus(status: result.status)
    entry.type = CKMLNTransactionType(type: result.type)
    entry.direction = CKMLNTransactionDirection(direction: result.direction)
    entry.value = result.value
    entry.networkFee = result.networkFee
    entry.processingFee = result.processingFee
    entry.error = result.error

    if entry.type == .lightning, let validRequest = result.request?.asNilIfEmpty() {
      entry.request = validRequest //result.request may be a non-invoice string when type is .btc
    }

    // User may have added local memo
    if let resultMemo = result.memo?.asNilIfEmpty(), entry.memo == nil {
      entry.memo = resultMemo
      entry.walletEntry?.memoSetByInvoice = true
    }

    if let setMemo = entry.memo?.asNilIfEmpty(), setMemo == result.memo {
      //scanning/pasting an invoice will populate the editable memo text field and may set it before the ledger result is fetched
      //this will give flexibility to the order of setting the memo and set the correct value if they are identical
      entry.walletEntry?.memoSetByInvoice = true
    }
  }

  static func find(withId id: String, wallet: CKMWallet?, in context: NSManagedObjectContext) -> CKMLNLedgerEntry? {
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
