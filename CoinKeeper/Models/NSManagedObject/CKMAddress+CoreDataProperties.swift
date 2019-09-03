//
//  CKMAddress+CoreDataProperties.swift
//  DropBit
//
//  Created by BJ Miller on 5/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMAddress {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMAddress> {
    return NSFetchRequest<CKMAddress>(entityName: "CKMAddress")
  }

  @NSManaged public var addressId: String
  @NSManaged public var addressTransactionSummaries: Set<CKMAddressTransactionSummary>
  @NSManaged public var derivativePath: CKMDerivativePath?
  @NSManaged public var vouts: Set<CKMVout>

}

// MARK: Generated accessors for addressTransactionSummaries
extension CKMAddress {

  @objc(addAddressTransactionSummariesObject:)
  @NSManaged public func addToAddressTransactionSummaries(_ value: CKMAddressTransactionSummary)

  @objc(removeAddressTransactionSummariesObject:)
  @NSManaged public func removeFromAddressTransactionSummaries(_ value: CKMAddressTransactionSummary)

  @objc(addAddressTransactionSummaries:)
  @NSManaged public func addToAddressTransactionSummaries(_ values: Set<CKMAddressTransactionSummary>)

  @objc(removeAddressTransactionSummaries:)
  @NSManaged public func removeFromAddressTransactionSummaries(_ values: Set<CKMAddressTransactionSummary>)

}

// MARK: Generated accessors for vouts
extension CKMAddress {

  @objc(addVoutsObject:)
  @NSManaged public func addToVouts(_ value: CKMVout)

  @objc(removeVoutsObject:)
  @NSManaged public func removeFromVouts(_ value: CKMVout)

  @objc(addVouts:)
  @NSManaged public func addToVouts(_ values: Set<CKMVout>)

  @objc(removeVouts:)
  @NSManaged public func removeFromVouts(_ values: Set<CKMVout>)

}
