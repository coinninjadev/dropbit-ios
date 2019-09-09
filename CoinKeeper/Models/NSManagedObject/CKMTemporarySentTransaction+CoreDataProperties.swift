//
//  TemporarySentTransaction+CoreDataProperties.swift
//  DropBit
//
//  Created by BJ Miller on 6/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMTemporarySentTransaction {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMTemporarySentTransaction> {
    return NSFetchRequest<CKMTemporarySentTransaction>(entityName: "CKMTemporarySentTransaction")
  }

  @NSManaged public var createdAt: Date
  @NSManaged public var amount: Int
  @NSManaged public var feeAmount: Int
  @NSManaged public var isSentToSelf: Bool
  @NSManaged public var transaction: CKMTransaction?

  /// The vouts that were reserved for this transaction by setting their isSpent = true
  @NSManaged public var reservedVouts: Set<CKMVout>

}
