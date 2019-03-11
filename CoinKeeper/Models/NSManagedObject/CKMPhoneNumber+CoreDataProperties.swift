//
//  CKMPhoneNumber+CoreDataProperties.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMPhoneNumber {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMPhoneNumber> {
    return NSFetchRequest<CKMPhoneNumber>(entityName: "CKMPhoneNumber")
  }

  @NSManaged public var countryCode: Int16
  @NSManaged public var number: Int
  @NSManaged public var status: String?
  @NSManaged public var phoneNumberHash: String
  @NSManaged public var counterparty: CKMCounterparty?
  @NSManaged public var invitations: Set<CKMInvitation>
  @NSManaged public var transactions: Set<CKMTransaction>

}

// MARK: Generated accessors for invitations
extension CKMPhoneNumber {

  @objc(addInvitationsObject:)
  @NSManaged public func addToInvitations(_ value: CKMInvitation)

  @objc(removeInvitationsObject:)
  @NSManaged public func removeFromInvitations(_ value: CKMInvitation)

  @objc(addInvitations:)
  @NSManaged public func addToInvitations(_ values: Set<CKMInvitation>)

  @objc(removeInvitations:)
  @NSManaged public func removeFromInvitations(_ values: Set<CKMInvitation>)

}

// MARK: Generated accessors for transactions
extension CKMPhoneNumber {

  @objc(addTransactionsObject:)
  @NSManaged public func addToTransactions(_ value: CKMTransaction)

  @objc(removeTransactionsObject:)
  @NSManaged public func removeFromTransactions(_ value: CKMTransaction)

  @objc(addTransactions:)
  @NSManaged public func addToTransactions(_ values: Set<CKMTransaction>)

  @objc(removeTransactions:)
  @NSManaged public func removeFromTransactions(_ values: Set<CKMTransaction>)

}
