//
//  CKMWalletEntry+CoreDataClass.swift
//
//
//  Created by Ben Winters on 8/9/19.
//
//

import Foundation
import CoreData

@objc(CKMWalletEntry)
public class CKMWalletEntry: NSManagedObject {

  convenience init(wallet: CKMWallet, sortDate: Date, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.wallet = wallet
    self.isHidden = false
    self.sortDate = sortDate
  }

  static func findTemporary(withId id: String, in context: NSManagedObjectContext) -> CKMWalletEntry? {
    let fetchRequest: NSFetchRequest<CKMWalletEntry> = CKMWalletEntry.fetchRequest()
    fetchRequest.predicate = CKPredicate.WalletEntry.tempId(id)
    fetchRequest.fetchLimit = 1

    do {
      return try context.fetch(fetchRequest).first
    } catch {
      log.error(error, message: "Failed to fetch temporary sent transaction for wallet entry")
      return nil
    }
  }

}

extension CKMWalletEntry: InvitationParent { }
