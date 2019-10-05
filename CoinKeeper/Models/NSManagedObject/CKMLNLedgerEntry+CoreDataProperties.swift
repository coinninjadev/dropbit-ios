//
//  CKMLNLedgerEntry+CoreDataProperties.swift
//  
//
//  Created by Ben Winters on 8/9/19.
//
//

import Foundation
import CoreData

@objc public enum CKMLNTransactionStatus: Int16 {
  case pending, completed, expired, failed

  init(status: LNTransactionStatus) {
    switch status {
    case .pending:    self = .pending
    case .completed:  self = .completed
    case .expired:    self = .expired
    case .failed:     self = .failed
    }
  }
}

@objc public enum CKMLNTransactionType: Int16 {
  case btc, lightning

  init(type: LNTransactionType) {
    switch type {
    case .btc:        self = .btc
    case .lightning:  self = .lightning
    }
  }
}

@objc public enum CKMLNTransactionDirection: Int16 {
  case `in`, out

  init(direction: LNTransactionDirection) {
    switch direction {
    case .in:   self = .in
    case .out:  self = .out
    }
  }
}

extension CKMLNLedgerEntry {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMLNLedgerEntry> {
    return NSFetchRequest<CKMLNLedgerEntry>(entityName: "CKMLNLedgerEntry")
  }

  @NSManaged public var id: String?
  @NSManaged public var accountId: String?
  @NSManaged public var createdAt: Date?
  @NSManaged public var updatedAt: Date?
  @NSManaged public var expiresAt: Date?
  @NSManaged public var status: CKMLNTransactionStatus
  @NSManaged public var type: CKMLNTransactionType
  @NSManaged public var direction: CKMLNTransactionDirection
  @NSManaged public var value: Int
  @NSManaged public var networkFee: Int
  @NSManaged public var processingFee: Int
  @NSManaged public var request: String?
  @NSManaged public var error: String?
  @NSManaged public var walletEntry: CKMWalletEntry?
  @NSManaged public var invoice: CKMLNInvoice?

  /// Be sure to set the walletEntry relationship before setting this memo
  var memo: String? {
    get { return walletEntry?.memo }
    set { walletEntry?.memo = newValue }
  }

  var transactionStatus: TransactionStatus {
    switch status {
    case .pending:    return .pending
    case .completed:  return .completed
    case .expired:    return .expired
    case .failed:     return .failed
    }
  }

}
