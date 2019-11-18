//
//  LightningBroker.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

class LightningBroker: CKPersistenceBroker, LightningBrokerType {

  func getAccount(forWallet wallet: CKMWallet, in context: NSManagedObjectContext) -> CKMLNAccount {
    return CKMLNAccount.findOrCreate(forWallet: wallet, in: context)
  }

  func persistAccountResponse(_ response: LNAccountResponse, in context: NSManagedObjectContext) {
    guard let wallet = CKMWallet.find(in: context) else { return }
    let account = getAccount(forWallet: wallet, in: context)
    account.update(with: response)
  }

  func persistLedgerResponse(_ response: LNLedgerResponse,
                             forWallet wallet: CKMWallet,
                             in context: NSManagedObjectContext) {
    response.ledger.forEach { CKMLNLedgerEntry.updateOrCreate(with: $0, forWallet: wallet, in: context) }
  }

  func persistPaymentResponse(_ response: LNTransactionResponse,
                              receiver: OutgoingDropBitReceiver?,
                              invitation: CKMInvitation?,
                              inputs: LightningPaymentInputs?,
                              in context: NSManagedObjectContext) {
    guard let wallet = CKMWallet.find(in: context) else { return }

    let ledgerEntry: CKMLNLedgerEntry

    if let invitation = invitation, let walletEntry = invitation.walletEntry {
      ledgerEntry = CKMLNLedgerEntry.create(with: response.result, walletEntry: walletEntry, in: context)
    } else {
      ///invitation and/or invitation.walletEntry are nil, create ledger entry for non-invite lightning transaction
      ledgerEntry = CKMLNLedgerEntry.updateOrCreate(with: response.result, forWallet: wallet, in: context)
    }

    if let receiver = receiver {
      ledgerEntry.walletEntry?.configure(withReceiver: receiver, in: context)
    }

    if let sharedPayload = inputs?.sharedPayload {
      ledgerEntry.walletEntry?.configureNewSenderSharedPayload(with: sharedPayload, in: context)
    }
  }

  func persistPaymentResponse(_ response: LNTransactionResponse, in context: NSManagedObjectContext) {
    self.persistPaymentResponse(response, receiver: nil, invitation: nil, inputs: nil, in: context)
  }

  func deleteInvalidWalletEntries(in context: NSManagedObjectContext) {
    let fetchRequest: NSFetchRequest<CKMWalletEntry> = CKMWalletEntry.fetchRequest()
    fetchRequest.predicate = CKPredicate.WalletEntry.invalid()

    var invalidWalletEntries: [CKMWalletEntry] = []
    do {
      invalidWalletEntries = try context.fetch(fetchRequest)
    } catch {
      log.error(error, message: "failed to fetch invalid wallet entries")
    }

    invalidWalletEntries.forEach { context.delete($0) }
  }

  func deleteInvalidLedgerEntries(in context: NSManagedObjectContext) {
    let fetchRequest: NSFetchRequest<CKMLNLedgerEntry> = CKMLNLedgerEntry.fetchRequest()
    fetchRequest.predicate = CKPredicate.LedgerEntry.invalid()

    var invalidLedgerEntries: [CKMLNLedgerEntry] = []
    do {
      invalidLedgerEntries = try context.fetch(fetchRequest)
    } catch {
      log.error(error, message: "failed to fetch invalid wallet entries")
    }

    invalidLedgerEntries.forEach { context.delete($0) }
  }

  func getLedgerEntriesWithoutPayloads(matchingIds ids: [String], in context: NSManagedObjectContext) -> [CKMLNLedgerEntry] {
    let fetchRequest: NSFetchRequest<CKMLNLedgerEntry> = CKMLNLedgerEntry.fetchRequest()
    fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [CKPredicate.LedgerEntry.idIn(ids),
                                                                             CKPredicate.LedgerEntry.withoutPayload(),
                                                                             CKPredicate.LedgerEntry.withStatus(.completed)])
    do {
      return try context.fetch(fetchRequest)
    } catch {
      log.error(error, message: "failed to fetch ledger entries without payloads")
      return []
    }
  }

}
