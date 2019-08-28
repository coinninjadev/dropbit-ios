//
//  CKMVin+CoreDataProperties.swift
//  DropBit
//
//  Created by BJ Miller on 5/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMVin {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMVin> {
    return NSFetchRequest<CKMVin>(entityName: "CKMVin")
  }

  @NSManaged public var addressIDs: [String]
  @NSManaged public var amount: Int
  @NSManaged public var belongsToWallet: Bool
  @NSManaged public var previousTxid: String?
  @NSManaged public var previousVoutIndex: Int
  @NSManaged public var transaction: CKMTransaction?

}
