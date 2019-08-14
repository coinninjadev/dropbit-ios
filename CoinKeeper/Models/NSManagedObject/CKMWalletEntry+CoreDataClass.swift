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

  public var isCancellable: Bool {
    return false //TODO
  }

  public var networkFee: Int {
    return 0 //TODO
  }
}
