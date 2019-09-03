//
//  CKMAddressTransactionSummary+CoreDataProperties.swift
//  DropBit
//
//  Created by BJ Miller on 5/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMAddressTransactionSummary {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMAddressTransactionSummary> {
    return NSFetchRequest<CKMAddressTransactionSummary>(entityName: "CKMAddressTransactionSummary")
  }

  @NSManaged public var received: Int
  @NSManaged public var sent: Int
  @NSManaged public var txid: String
  @NSManaged public var addressId: String
  @NSManaged public var isChangeAddress: Bool
  @NSManaged public var wallet: CKMWallet?
  @NSManaged public var transaction: CKMTransaction?
  @NSManaged public var address: CKMAddress?

}
