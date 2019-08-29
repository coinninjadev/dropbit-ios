//
//  CKMWalletEntry+CoreDataClass.swift
//
//
//  Created by Ben Winters on 8/9/19.
//
//

import Foundation
import CoreData

@objc(CKMWalletEntry)
public class CKMWalletEntry: NSManagedObject {

  convenience init(wallet: CKMWallet, sortDate: Date, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.wallet = wallet
    self.isHidden = false
    self.sortDate = sortDate
  }

  public var isCancellable: Bool {
    return false //TODO
  }

  public var networkFee: Int {
    return 0 //TODO
  }
}
