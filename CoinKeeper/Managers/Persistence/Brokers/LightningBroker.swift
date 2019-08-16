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

  func getAccount(forWallet wallet: CKMWallet, in context: NSManagedObjectContext) -> CKMLNAccount {
    return CKMLNAccount.findOrCreate(forWallet: wallet, in: context)
  }

  func persistAccountResponse(_ response: LNAccountResponse,
                              forWallet wallet: CKMWallet,
                              in context: NSManagedObjectContext) {
    let account = getAccount(forWallet: wallet, in: context)
    account.update(with: response)
  }

}
