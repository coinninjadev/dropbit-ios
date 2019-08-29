//
//  CKMTransaction+CoreDataProperties.swift
//  DropBit
//
//  Created by BJ Miller on 7/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMTransaction {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMTransaction> {
    return NSFetchRequest<CKMTransaction>(entityName: "CKMTransaction")
  }

  @NSManaged public var blockHash: String?
  @NSManaged public var confirmations: Int
  @NSManaged public var date: Date?
  @NSManaged public var network: String?
  @NSManaged public var dayAveragePrice: NSDecimalNumber? //average price of 1 BTC in USD, for the day of the transaction
  @NSManaged public var sortDate: Date?
  @NSManaged public var broadcastedAt: Date?
  @NSManaged public var txid: String
  @NSManaged public var isSentToSelf: Bool
  @NSManaged public var addressTransactionSummaries: Set<CKMAddressTransactionSummary>
  @NSManaged public var invitation: CKMInvitation?
  @NSManaged public var temporarySentTransaction: CKMTemporarySentTransaction?
  @NSManaged public var vins: Set<CKMVin>
  @NSManaged public var vouts: Set<CKMVout>
  @NSManaged public var phoneNumber: CKMPhoneNumber?
  @NSManaged public var twitterContact: CKMTwitterContact?
  @NSManaged public var counterpartyAddress: CKMCounterpartyAddress?
  @NSManaged public var isIncoming: Bool
  @NSManaged public var memo: String?
  @NSManaged public var sharedPayload: CKMTransactionSharedPayload?

  /**
   The broadcast was "successful" but the transaction never showed up on the mempool.
   In such a case, this property is set to false during grooming. Default value is false.
   */
  @NSManaged public var broadcastFailed: Bool

}

// MARK: Generated accessors for addressTransactionSummaries
extension CKMTransaction {

  @objc(addAddressTransactionSummariesObject:)
  @NSManaged public func addToAddressTransactionSummaries(_ value: CKMAddressTransactionSummary)

  @objc(removeAddressTransactionSummariesObject:)
  @NSManaged public func removeFromAddressTransactionSummaries(_ value: CKMAddressTransactionSummary)

  @objc(addAddressTransactionSummaries:)
  @NSManaged public func addToAddressTransactionSummaries(_ values: Set<CKMAddressTransactionSummary>)

  @objc(removeAddressTransactionSummaries:)
  @NSManaged public func removeFromAddressTransactionSummaries(_ values: Set<CKMAddressTransactionSummary>)

}

// MARK: Generated accessors for vins
extension CKMTransaction {

  @objc(addVinsObject:)
  @NSManaged public func addToVins(_ value: CKMVin)

  @objc(removeVinsObject:)
  @NSManaged public func removeFromVins(_ value: CKMVin)

  @objc(addVins:)
  @NSManaged public func addToVins(_ values: Set<CKMVin>)

  @objc(removeVins:)
  @NSManaged public func removeFromVins(_ values: Set<CKMVin>)

}

// MARK: Generated accessors for vouts
extension CKMTransaction {

  @objc(addVoutsObject:)
  @NSManaged public func addToVouts(_ value: CKMVout)

  @objc(removeVoutsObject:)
  @NSManaged public func removeFromVouts(_ value: CKMVout)

  @objc(addVouts:)
  @NSManaged public func addToVouts(_ values: Set<CKMVout>)

  @objc(removeVouts:)
  @NSManaged public func removeFromVouts(_ values: Set<CKMVout>)

}
