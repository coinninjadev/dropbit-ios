//
//  CKMVout+CoreDataProperties.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMVout {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMVout> {
    return NSFetchRequest<CKMVout>(entityName: "CKMVout")
  }

  @NSManaged public var addressIDs: [String]
  @NSManaged public var amount: Int
  @NSManaged public var index: Int
  @NSManaged public var isSpent: Bool
  @NSManaged public var txid: String?  // This is for uniquely constraining the vout instance, with `index`
  @NSManaged public var address: CKMAddress?
  @NSManaged public var transaction: CKMTransaction?

  /// The tempTx which reserved this vout by marking its isSpent = true
  @NSManaged public var temporarySentTransaction: CKMTemporarySentTransaction?

}
