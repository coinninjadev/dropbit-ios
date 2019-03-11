//
//  CKMWallet+CoreDataProperties.swift
//  CoinKeeper
//
//  Created by BJ Miller on 5/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMWallet {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMWallet> {
    return NSFetchRequest<CKMWallet>(entityName: "CKMWallet")
  }

  @NSManaged public var id: String? //provided by server
  @NSManaged public var lastSyncBlockHash: String?
  @NSManaged public var lastSyncDate: Date?
  @NSManaged public var lastReceivedIndex: Int //default -1
  @NSManaged public var lastChangeIndex: Int //default -1
  @NSManaged public var addressTransactionSummaries: Set<CKMAddressTransactionSummary>
  @NSManaged public var serverAddresses: Set<CKMServerAddress>
  @NSManaged public var user: CKMUser?

}

// MARK: Generated accessors for addressTransactionSummaries
extension CKMWallet {

  @objc(addAddressTransactionSummariesObject:)
  @NSManaged public func addToAddressTransactionSummaries(_ value: CKMAddressTransactionSummary)

  @objc(removeAddressTransactionSummariesObject:)
  @NSManaged public func removeFromAddressTransactionSummaries(_ value: CKMAddressTransactionSummary)

  @objc(addAddressTransactionSummaries:)
  @NSManaged public func addToAddressTransactionSummaries(_ values: Set<CKMAddressTransactionSummary>)

  @objc(removeAddressTransactionSummaries:)
  @NSManaged public func removeFromAddressTransactionSummaries(_ values: Set<CKMAddressTransactionSummary>)

}
