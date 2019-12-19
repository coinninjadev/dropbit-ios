//
//  MockWalletBroker.swift
//  DropBitTests
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Cnlib
import CoreData
import Foundation
import PromiseKit
@testable import DropBit

class MockWalletBroker: CKPersistenceBroker, WalletBrokerType {

  var walletIdValue: String?
  func walletId(in context: NSManagedObjectContext) -> String? {
    return walletIdValue
  }

  func walletFlags(in context: NSManagedObjectContext) -> WalletFlagsParser {
    return WalletFlagsParser(flags: 0)
  }

  func resetWallet() throws { }

  func walletWords() -> [String]? {
    return keychainManager.retrieveValue(for: .walletWords) as? [String]
  }

  func persistWalletResponse(from response: WalletResponse, in context: NSManagedObjectContext) throws { }

  var removeWalletIdWasCalled = false
  func removeWalletId(in context: NSManagedObjectContext) {
    removeWalletIdWasCalled = true
  }

  func deleteWallet(in context: NSManagedObjectContext) { }

  func backup(recoveryWords words: [String], isBackedUp: Bool) -> Promise<Void> {
    return Promise { _ in }
  }

  func walletWordsBackedUp() -> Bool {
    return keychainManager.walletWordsBackedUp()
  }

  func persistAddedWalletAddresses(from responses: [WalletAddressResponse],
                                   metaAddresses: [CNBCnlibMetaAddress],
                                   in context: NSManagedObjectContext) -> Promise<Void> {
    return Promise { _ in }
  }

  func updateWalletLastIndexes(in context: NSManagedObjectContext) { }

  func lastChangeAddressIndex(in context: NSManagedObjectContext) -> Int? {
    return nil
  }

  var lastReceiveAddressIndexValue: Int?
  func lastReceiveAddressIndex(in context: NSManagedObjectContext) -> Int? {
    return lastReceiveAddressIndexValue
  }

  var receiveAddressIndexGapsValue: Set<Int> = []
  var receiveAddressIndexGaps: Set<Int> {
    get {
      return receiveAddressIndexGapsValue
    }
    set {
      receiveAddressIndexGapsValue = newValue
    }
  }

  var usableCoin: CNBCnlibBasecoin {
    return CNBCnlibNewBaseCoin(84, 0, 0)!
  }

}
