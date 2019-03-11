//
//  CKMTransactionSharedPayload+CoreDataClass.swift
//  DropBit
//
//  Created by Ben Winters on 1/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

@objc(CKMTransactionSharedPayload)
public class CKMTransactionSharedPayload: NSManagedObject {

  public override func awakeFromInsert() {
    super.awakeFromInsert()
    setPrimitiveValue(false, forKey: #keyPath(CKMTransactionSharedPayload.sharingDesired))
    setPrimitiveValue(0, forKey: #keyPath(CKMTransactionSharedPayload.fiatAmount))
    setPrimitiveValue("", forKey: #keyPath(CKMTransactionSharedPayload.fiatCurrency))
  }

  convenience init(sharingDesired: Bool,
                   fiatAmount: Int,
                   fiatCurrency: String,
                   receivedPayload: Data?,
                   insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.sharingDesired = sharingDesired
    self.fiatAmount = fiatAmount
    self.fiatCurrency = fiatCurrency
    self.receivedPayload = receivedPayload
  }

}
