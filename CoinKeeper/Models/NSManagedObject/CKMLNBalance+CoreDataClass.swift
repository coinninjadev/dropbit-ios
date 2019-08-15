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

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMLNBalance> {
    return NSFetchRequest<CKMLNBalance>(entityName: "CKMLNBalance")
  }

  static func findOrCreate(in context: NSManagedObjectContext) -> CKMLNBalance {
    let fetchRequest: NSFetchRequest<CKMLNBalance> = CKMLNBalance.fetchRequest()
    fetchRequest.fetchLinit = 1

    var result: [CKMAddressTransactionSummary] = []
    context.performAndWait {
      do {
        result = try context.fetch(fetchRequest)
      } catch {
        result = []
      }
    }
    return result
  }

}
