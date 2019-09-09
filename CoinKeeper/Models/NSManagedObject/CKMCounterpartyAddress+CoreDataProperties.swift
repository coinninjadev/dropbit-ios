//
//  CKMCounterpartyAddress+CoreDataProperties.swift
//  DropBit
//
//  Created by BJ Miller on 6/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMCounterpartyAddress {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMCounterpartyAddress> {
    return NSFetchRequest<CKMCounterpartyAddress>(entityName: "CKMCounterpartyAddress")
  }

  @NSManaged public var addressId: String
  @NSManaged public var transactions: Set<CKMTransaction>

}

// MARK: Generated accessors for transactions
extension CKMCounterpartyAddress {

  @objc(addTransactionsObject:)
  @NSManaged public func addToTransactions(_ value: CKMTransaction)

  @objc(removeTransactionsObject:)
  @NSManaged public func removeFromTransactions(_ value: CKMTransaction)

  @objc(addTransactions:)
  @NSManaged public func addToTransactions(_ values: Set<CKMTransaction>)

  @objc(removeTransactions:)
  @NSManaged public func removeFromTransactions(_ values: Set<CKMTransaction>)

}
