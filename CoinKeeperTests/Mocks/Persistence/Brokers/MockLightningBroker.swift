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

  var getAccountCalled = false
  func getAccount(forWallet wallet: CKMWallet, in context: NSManagedObjectContext) -> CKMLNAccount {
    let account = CKMLNAccount(insertInto: context)
    getAccountCalled = true
    return account
  }

  func persistAccountResponse(_ response: LNAccountResponse,
                              forWallet wallet: CKMWallet,
                              in context: NSManagedObjectContext) {
  }

}
