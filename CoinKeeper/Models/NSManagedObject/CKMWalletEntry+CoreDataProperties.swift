//
//  CKMWalletEntry+CoreDataProperties.swift
//  
//
//  Created by Ben Winters on 8/9/19.
//
//

import Foundation
import CoreData

extension CKMWalletEntry {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMWalletEntry> {
    return NSFetchRequest<CKMWalletEntry>(entityName: "CKMWalletEntry")
  }

  static let transactionHistorySortDescriptors: [NSSortDescriptor] = [
    NSSortDescriptor(key: #keyPath(CKMWalletEntry.sortDate), ascending: false)
  ]

  @NSManaged public var sortDate: Date
  @NSManaged public var isHidden: Bool
  @NSManaged public var memo: String?

  ///If `memo` is set, this indicates whether it was part of the original (shared) lightning invoice.
  ///Otherwise it may have been part of the shared payload or set manually by the user.
  @NSManaged public var memoSetByInvoice: Bool

  @NSManaged public var wallet: CKMWallet?
  @NSManaged public var ledgerEntry: CKMLNLedgerEntry?
  @NSManaged public var twitterContact: CKMTwitterContact?
  @NSManaged public var phoneNumber: CKMPhoneNumber?
  @NSManaged public var sharedPayload: CKMTransactionSharedPayload?
  @NSManaged public var invitation: CKMInvitation?
  @NSManaged public var temporarySentTransaction: CKMTemporarySentTransaction?

}
