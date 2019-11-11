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
  func persistPaymentResponse(_ response: LNTransactionResponse, receiver: OutgoingDropBitReceiver?,
                              invitation: CKMInvitation?, inputs: LightningPaymentInputs?,
                              in context: NSManagedObjectContext) {}

  var getAccountCalled = false
  func getAccount(forWallet wallet: CKMWallet, in context: NSManagedObjectContext) -> CKMLNAccount {
    let account = CKMLNAccount(insertInto: context)
    getAccountCalled = true
    return account
  }

  func persistAccountResponse(_ response: LNAccountResponse,
                              forWallet wallet: CKMWallet,
                              in context: NSManagedObjectContext) { }

  func persistLedgerResponse(_ response: LNLedgerResponse,
                             forWallet wallet: CKMWallet,
                             in context: NSManagedObjectContext) { }

  func deleteInvalidWalletEntries(in context: NSManagedObjectContext) { }
  func deleteInvalidLedgerEntries(in context: NSManagedObjectContext) { }

  func getLedgerEntriesWithoutPayloads(matchingIds ids: [String],
                                       limit: Int,
                                       in context: NSManagedObjectContext) -> [CKMLNLedgerEntry] {
    return []
  }

}
