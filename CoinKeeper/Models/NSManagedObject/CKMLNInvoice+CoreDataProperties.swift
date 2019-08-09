//
//  CKMLNInvoice+CoreDataProperties.swift
//  
//
//  Created by Ben Winters on 8/9/19.
//
//

import Foundation
import CoreData

extension CKMLNInvoice {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMLNInvoice> {
    return NSFetchRequest<CKMLNInvoice>(entityName: "CKMLNInvoice")
  }

  @NSManaged public var destination: String?
  @NSManaged public var paymentHash: String?
  @NSManaged public var numSatoshis: Int
  @NSManaged public var timestamp: Date?
  @NSManaged public var expiry: Int
  @NSManaged public var desc: String?
  @NSManaged public var descHash: String?
  @NSManaged public var fallbackAddr: String?
  @NSManaged public var cltvExpiry: Int
  @NSManaged public var ledgerEntry: CKMLNLedgerEntry?

}
