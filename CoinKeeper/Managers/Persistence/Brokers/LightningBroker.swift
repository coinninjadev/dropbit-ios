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

  func persistLedgerResponse(_ response: LNLedgerResponse,
                             forWallet wallet: CKMWallet,
                             in context: NSManagedObjectContext) {
    response.ledger.forEach { CKMLNLedgerEntry.updateOrCreate(with: $0, forWallet: wallet, in: context) }
  }

  func persistPaymentResponse(_ response: LNTransactionResponse,
                              receiver: OutgoingDropBitReceiver?,
                              inputs: LightningPaymentInputs,
                              in context: NSManagedObjectContext) {
    guard let wallet = CKMWallet.find(in: context) else { return }
    let ledgerEntry = CKMLNLedgerEntry.updateOrCreate(with: response.result, forWallet: wallet, in: context)
    if let receiver = receiver {
      ledgerEntry.walletEntry?.configure(withReceiver: receiver, in: context)
    }

    if let sharedPayload = inputs.sharedPayload {
      ledgerEntry.walletEntry?.configureNewSenderSharedPayload(with: sharedPayload, in: context)
    }
  }

}
