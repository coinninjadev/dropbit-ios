//
//  CKMWallet+CoreDataClass.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CKMWallet)
public class CKMWallet: NSManagedObject {

  public override func awakeFromInsert() {
    super.awakeFromInsert()
    setPrimitiveValue(CKMWallet.defaultLastIndex, forKey: #keyPath(CKMWallet.lastReceivedIndex))
    setPrimitiveValue(CKMWallet.defaultLastIndex, forKey: #keyPath(CKMWallet.lastChangeIndex))
  }

  // Setting -1 as the default value ensures that getting nextReceiveIndex will start at 0
  static let defaultLastIndex: Int = -1

  @discardableResult
  static func findOrCreate(in context: NSManagedObjectContext) -> CKMWallet {
    if let foundWallet = find(in: context) {
      return foundWallet
    } else {
      return CKMWallet(insertInto: context)
    }
  }

  static func find(in context: NSManagedObjectContext) -> CKMWallet? {
    let fetchRequest: NSFetchRequest<CKMWallet> = CKMWallet.fetchRequest()
    fetchRequest.fetchLimit = 1

    var wallet: CKMWallet?
    context.performAndWait {
      do {
        let results = try context.fetch(fetchRequest)
        wallet = results.first
      } catch {
        wallet = nil
      }
    }
    return wallet
  }

}
