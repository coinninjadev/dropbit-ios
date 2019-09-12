//
//  CKMTwitterContact+CoreDataProperties.swift
//  DropBit
//
//  Created by BJ Miller on 5/17/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMTwitterContact {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMTwitterContact> {
    return NSFetchRequest<CKMTwitterContact>(entityName: "CKMTwitterContact")
  }

  @NSManaged public var identityHash: String
  @NSManaged public var displayName: String
  @NSManaged public var displayScreenName: String
  @NSManaged public var profileImageData: Data?
  @NSManaged public var verificationStatus: UserIdentityVerificationStatus
  @NSManaged public var verifiedTwitterUser: Bool
  @NSManaged public var transactions: Set<CKMTransaction>
  @NSManaged public var invitations: Set<CKMInvitation>
  @NSManaged public var walletEntries: Set<CKMWalletEntry>

}

// MARK: Generated accessors for transactions
extension CKMTwitterContact {

  @objc(addTransactionsObject:)
  @NSManaged public func addToTransactions(_ value: CKMTransaction)

  @objc(removeTransactionsObject:)
  @NSManaged public func removeFromTransactions(_ value: CKMTransaction)

  @objc(addTransactions:)
  @NSManaged public func addToTransactions(_ values: NSSet)

  @objc(removeTransactions:)
  @NSManaged public func removeFromTransactions(_ values: NSSet)

}

// MARK: Generated accessors for invitations
extension CKMTwitterContact {

  @objc(addInvitationsObject:)
  @NSManaged public func addToInvitations(_ value: CKMInvitation)

  @objc(removeInvitationsObject:)
  @NSManaged public func removeFromInvitations(_ value: CKMInvitation)

  @objc(addInvitations:)
  @NSManaged public func addToInvitations(_ values: NSSet)

  @objc(removeInvitations:)
  @NSManaged public func removeFromInvitations(_ values: NSSet)

}
