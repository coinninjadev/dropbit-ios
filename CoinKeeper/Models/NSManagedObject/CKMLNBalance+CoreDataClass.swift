//
//  CKMLNBalance+CoreDataClass.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

@objc(CKMLNBalance)
public class CKMLNBalance: NSManagedObject {

  public override func awakeFromInsert() {
    super.awakeFromInsert()
    setPrimitiveValue(0, forKey: #keyPath(CKMLNBalance.balance))
    setPrimitiveValue(0, forKey: #keyPath(CKMLNBalance.pendingIn))
    setPrimitiveValue(0, forKey: #keyPath(CKMLNBalance.pendingOut))
  }

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMLNBalance> {
    return NSFetchRequest<CKMLNBalance>(entityName: "CKMLNBalance")
  }

  @discardableResult
  static func findOrCreate(in context: NSManagedObjectContext) -> CKMLNBalance {
    if let foundBalance = find(in: context) {
      return foundBalance
    } else {
      let balance = CKMLNBalance(insertInto: context)
      return balance
    }
  }

  static func find(in context: NSManagedObjectContext) -> CKMLNBalance? {
    let fetchRequest: NSFetchRequest<CKMLNBalance> = CKMLNBalance.fetchRequest()
    fetchRequest.fetchLimit = 1

    var balance: CKMLNBalance?
    context.performAndWait {
      do {
        let results = try context.fetch(fetchRequest)
        balance = results.first
      } catch {
        balance = nil
      }
    }
    return balance
  }

}
