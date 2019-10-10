//
//  CKMTransactionSharedPayload+CoreDataProperties.swift
//  DropBit
//
//  Created by Ben Winters on 1/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

extension CKMTransactionSharedPayload {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMTransactionSharedPayload> {
    return NSFetchRequest<CKMTransactionSharedPayload>(entityName: "CKMTransactionSharedPayload")
  }

  /// Represents that the sender shared a memo, not all shared payloads include a memo
  @NSManaged public var sharingDesired: Bool
  @NSManaged public var fiatAmount: Int
  @NSManaged public var fiatCurrency: String
  @NSManaged public var receivedPayload: Data?
  @NSManaged public var transaction: CKMTransaction?
  @NSManaged public var walletEntry: CKMWalletEntry?

}
