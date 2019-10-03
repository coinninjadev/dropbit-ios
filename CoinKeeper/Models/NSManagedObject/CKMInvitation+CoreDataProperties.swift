//
//  CKMInvitation+CoreDataProperties.swift
//  DropBit
//
//  Created by BJ Miller on 5/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMInvitation {

  public override func awakeFromInsert() {
    super.awakeFromInsert()
    setPrimitiveValue(1, forKey: #keyPath(CKMInvitation.fees))
  }

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMInvitation> {
    return NSFetchRequest<CKMInvitation>(entityName: "CKMInvitation")
  }

  @NSManaged public var id: String
  @NSManaged public var btcAmount: Int
  @NSManaged public var usdAmountAtTimeOfInvitation: Int
  @NSManaged private(set) var fees: Int
  @NSManaged public var sentDate: Date?
  @NSManaged private(set) var walletTransactionType: String
  @NSManaged public var side: InvitationSide
  @NSManaged public var status: InvitationStatus
  @NSManaged public var counterpartyName: String?
  @NSManaged public var counterpartyPhoneNumber: CKMPhoneNumber?
  @NSManaged public var counterpartyTwitterContact: CKMTwitterContact?
  @NSManaged public var transaction: CKMTransaction?
  @NSManaged public var walletEntry: CKMWalletEntry?
  @NSManaged public var addressProvidedToSender: String?

  /**
   Txid of the broadcasted transaction, supplied by sender. Use this to link the eventual transaction with this invitation.
   The linked Transaction object may or may not match this, if it is only a placeholder for the eventual transaction.
   */
  @NSManaged public private(set) var txid: String?

  /**
   Set to current timestamp when the txid is set and the status changes to .completed.
   This is not necessarily the same as the transaction time, particularly on the receiver side.
   */
  @NSManaged public var completedAt: Date?

  var sanitizedId: String {
    return id.replacingOccurrences(of: CKMInvitation.unacknowledgementPrefix, with: "")
  }

  func setTxid(to txid: String?) {
    self.txid = txid
    if (txid ?? "").isNotEmpty { // Don't set completedAt if setting txid to nil or empty string
      if self.completedAt == nil { // Prevent overwriting completedAt once it is set
        self.completedAt = Date()
      }
    } else {
      self.completedAt = nil
    }
  }

  func setFlatFee(to flatFee: Int) {
    self.fees = max(flatFee, 1)
  }

  func setStatusIfDifferent(to newStatus: InvitationStatus) {
    if status != newStatus {
      status = newStatus
    }
  }

  var walletTxTypeCase: WalletTransactionType {
    get { return WalletTransactionType(rawValue: walletTransactionType) ?? .onChain }
    set { self.walletTransactionType = newValue.rawValue }
  }

  var transactionStatus: TransactionStatus {
    switch status {
    case .notSent,
         .requestSent,
         .addressSent:  return .pending
    case .canceled:     return .canceled
    case .expired:      return .expired
    case .completed:    return .completed
    }
  }

}
