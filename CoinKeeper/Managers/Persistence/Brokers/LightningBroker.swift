//
//  LightningBroker.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

class LightningBroker: CKPersistenceBroker, LightningBrokerType {

  func getLightningBalance(in context: NSManagedObjectContext) -> CKMLNBalance {
      return CKMLNBalance.findOrCreate(in: context)
  }

}
