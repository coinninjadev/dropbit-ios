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
    configure(entry, with: result, in: context)
    return entry
  }

  static let lastLedgerSortDescriptor: [NSSortDescriptor] = [
    NSSortDescriptor(key: #keyPath(CKMLNLedgerEntry.createdAt), ascending: false)
  ]

  static func findOrCreate(with id: String, wallet: CKMWallet, createdAt: Date, in context: NSManagedObjectContext) -> CKMLNLedgerEntry {
    if let foundEntry = find(withId: id, wallet: wallet, in: context) {
      return foundEntry
    } else {
      let newEntry = CKMLNLedgerEntry(insertInto: context)
      newEntry.id = id

      ///CKMWalletEntry with a temporary sent transaction matching the id
      let maybeFoundTempWalletEntry = CKMWalletEntry.findTemporary(withId: id, in: context)

      ///CKMWalletEntry with a preauthorized lightning invitation matching the id
      let idIsPreauth = id.starts(with: LNTransactionResult.preauthPrefix)
      let maybePreauthWalletEntry: CKMWalletEntry? = idIsPreauth ? CKMWalletEntry.find(withPreauthId: id, in: context) : nil

      if let existingWalletEntry = maybeFoundTempWalletEntry ?? maybePreauthWalletEntry {
        newEntry.walletEntry = existingWalletEntry
      } else {
        newEntry.walletEntry = CKMWalletEntry(wallet: wallet, sortDate: createdAt, insertInto: context)
      }

      return newEntry
    }
  }

  static func create(with response: LNTransactionResult, walletEntry: CKMWalletEntry, in context: NSManagedObjectContext) -> CKMLNLedgerEntry {
    let newEntry = CKMLNLedgerEntry(insertInto: context)
    walletEntry.ledgerEntry = newEntry
    newEntry.walletEntry = walletEntry //set relationships first so that walletEntry properties can be set during configure()
    configure(newEntry, with: response, in: context)
    return newEntry
  }

  private static func configure(_ entry: CKMLNLedgerEntry, with result: LNTransactionResult, in context: NSManagedObjectContext) {
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

    if let tempSentTx = entry.walletEntry?.temporarySentTransaction {
      context.delete(tempSentTx)
    }

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

  static func findLatest(in context: NSManagedObjectContext) -> CKMLNLedgerEntry? {
    let fetchRequest: NSFetchRequest<CKMLNLedgerEntry> = CKMLNLedgerEntry.fetchRequest()
    fetchRequest.fetchLimit = 1
    fetchRequest.sortDescriptors = lastLedgerSortDescriptor

    do {
      return try context.fetch(fetchRequest).first
    } catch {
      log.error(error, message: "Could not execute fetch request for latest transaction")
      return nil
    }
  }

  static func findPreauthEntries(in context: NSManagedObjectContext) -> [CKMLNLedgerEntry] {
    let fetchRequest: NSFetchRequest<CKMLNLedgerEntry> = CKMLNLedgerEntry.fetchRequest()
    let predicates = [CKPredicate.LedgerEntry.hasPreauthIdPrefix(),
                      CKPredicate.LedgerEntry.withStatus(.pending)]
    fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)

    do {
      return try context.fetch(fetchRequest)
    } catch {
      log.error(error, message: "Failed to fetch preauth ledger entries")
      return []
    }
  }

  static func find(withId id: String, wallet: CKMWallet?, in context: NSManagedObjectContext) -> CKMLNLedgerEntry? {
    let idPredicate = CKPredicate.LedgerEntry.id(id)
    var andPredicates = [idPredicate]

    if let wallet = wallet {
      andPredicates.append(CKPredicate.LedgerEntry.wallet(wallet))
    }

    let fetchRequest: NSFetchRequest<CKMLNLedgerEntry> = CKMLNLedgerEntry.fetchRequest()
    fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: andPredicates)
    fetchRequest.fetchLimit = 1

    do {
      return try context.fetch(fetchRequest).first
    } catch {
      log.error(error, message: "Failed to fetch ledger entry for id: \(id)")
      return nil
    }
  }
}
