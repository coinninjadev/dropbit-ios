//
//  MockWalletBroker.swift
//  DropBitTests
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import Foundation
import PromiseKit
@testable import DropBit

class MockWalletBroker: CKPersistenceBroker, WalletBrokerType {
  func walletId(in context: NSManagedObjectContext) -> String? {
    return nil
  }

  func resetWallet() throws { }

  func walletWords() -> [String]? {
    return nil
  }

  func persistWalletId(from response: WalletResponse, in context: NSManagedObjectContext) throws { }

  func removeWalletId(in context: NSManagedObjectContext) { }

  func deleteWallet(in context: NSManagedObjectContext) { }

  func backup(recoveryWords words: [String], isBackedUp: Bool) -> Promise<Void> {
    return Promise { _ in }
  }

  func walletWordsBackedUp() -> Bool {
    return false
  }

  func persistAddedWalletAddresses(from responses: [WalletAddressResponse], metaAddresses: [CNBMetaAddress], in context: NSManagedObjectContext) -> Promise<Void> {
    return Promise { _ in }
  }

  func updateWalletLastIndexes(in context: NSManagedObjectContext) { }

  func lastReceiveAddressIndex(in context: NSManagedObjectContext) -> Int? {
    return nil
  }

  func lastChangeAddressIndex(in context: NSManagedObjectContext) -> Int? {
    return nil
  }

  var receiveAddressIndexGaps: Set<Int> = []


}
