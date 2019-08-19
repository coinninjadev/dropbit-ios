//
//  MockLightningBroker.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/16/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

class MockLightningBroker: CKPersistenceBroker, LightningBrokerType {

  var getBalanceCalled = false
  func getBalance(in context: NSManagedObjectContext) -> CKMLNBalance {
    let balance = CKMLNBalance(insertInto: context)
    getBalanceCalled = true
    return balance
  }

}
