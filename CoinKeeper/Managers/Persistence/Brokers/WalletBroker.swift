//
//  WalletBroker.swift
//  DropBit
//
//  Created by Ben Winters on 6/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import CNBitcoinKit
import PromiseKit

class WalletBroker: CKPersistenceBroker, WalletBrokerType {

  func walletId(in context: NSManagedObjectContext) -> String? {
    if let walletID = userDefaultsManager.string(for: .walletID) {
      return walletID
    } else {
      guard let walletID = databaseManager.walletId(in: context) else { return nil }
      self.userDefaultsManager.set(stringValue: walletID, for: .walletID)
      return walletID
    }
  }

  func walletFlags(in context: NSManagedObjectContext) -> WalletFlagsParser {
    return WalletFlagsParser(flags: databaseManager.walletFlags(in: context))
  }

  func resetWallet() throws {
    let bgContext = self.databaseManager.createBackgroundContext()
    self.deleteWallet(in: bgContext)
    try bgContext.performThrowingAndWait {
      _ = CKMWallet.findOrCreate(in: bgContext)
      try bgContext.saveRecursively()
    }
  }

  func walletWords() -> [String]? {
    let segwitWords = keychainManager.retrieveValue(for: .walletWordsV2) as? [String]
    let maybeLegacyWords = keychainManager.retrieveValue(for: .walletWords) as? [String]
    if let words = segwitWords, words.count == 12 {
      return words
    } else if let words = maybeLegacyWords, words.count == 12 {
      return words
    }
    return nil
  }

  func persistWalletResponse(from response: WalletResponse, in context: NSManagedObjectContext) throws {
    userDefaultsManager.set(stringValue: response.id, for: .walletID)
    try databaseManager.persistWalletResponse(response, in: context)
  }

  func removeWalletId(in context: NSManagedObjectContext) {
    databaseManager.removeWalletId(in: context)
    userDefaultsManager.removeValue(for: .walletID)
  }

  func deleteWallet(in context: NSManagedObjectContext) {
    databaseManager.deleteAll(in: context)
    userDefaultsManager.deleteWallet()
    keychainManager.deleteAll()
  }

  func walletWordsBackedUp() -> Bool {
    return keychainManager.walletWordsBackedUp()
  }

  /// The responses should correspond 1-to-1 with the metaAddresses, order is irrelevant.
  func persistAddedWalletAddresses(
    from responses: [WalletAddressResponse],
    metaAddresses: [CNBMetaAddress],
    in context: NSManagedObjectContext) -> Promise<Void> {
    return Promise { seal in

      guard let wallet = CKMWallet.find(in: context) else {
        seal.reject(CKPersistenceError.noManagedWallet)
        return
      }

      var persistencePromises: [Promise<Void>] = []
      for response in responses {
        guard let matchingMetaAddress = metaAddresses.filter({ $0.address == response.address }).first else {
          seal.reject(WalletAddressError.unexpectedAddress)
          return
        }

        let promise = databaseManager.persistServerAddress(for: matchingMetaAddress, createdAt: response.createdAt, wallet: wallet, in: context)
        persistencePromises.append(promise)
      }

      when(fulfilled: persistencePromises)
        .done { seal.fulfill(()) }
        .catch { error in seal.reject(error) }
    }
  }

  func updateWalletLastIndexes(in context: NSManagedObjectContext) {
    let lastReceiveIndex = CKMDerivativePath.maxUsedReceiveIndex(forCoin: usableCoin, in: context)
    let lastChangeIndex = CKMDerivativePath.maxUsedChangeIndex(forCoin: usableCoin, in: context)
    databaseManager.updateLastReceiveAddressIndex(index: lastReceiveIndex, in: context)
    databaseManager.updateLastChangeAddressIndex(index: lastChangeIndex, in: context)
  }

  func lastReceiveAddressIndex(in context: NSManagedObjectContext) -> Int? {
    return databaseManager.lastReceiveIndex(in: context)
  }

  func lastChangeAddressIndex(in context: NSManagedObjectContext) -> Int? {
    return databaseManager.lastChangeIndex(in: context)
  }

  var receiveAddressIndexGaps: Set<Int> {
    get {
      if let gaps = userDefaultsManager.array(for: .receiveAddressIndexGaps) as? [Int] {
        return Set(gaps)
      } else {
        return Set<Int>()
      }
    }
    set {
      let numbers: [NSNumber] = Array(newValue).map { NSNumber(value: $0) } // map Set<Int> to [NSNumber]
      userDefaultsManager.set(NSArray(array: numbers), for: .receiveAddressIndexGaps)
    }
  }

  var usableCoin: CNBBaseCoin {
    var coinType: CoinType = .MainNet
    #if DEBUG
//    coinType = .TestNet
    #endif
    let possibleSegwitWords = keychainManager.retrieveValue(for: .walletWordsV2) as? [String]
    if let words = possibleSegwitWords, words.count == 12 {
      return CNBBaseCoin(purpose: .BIP84, coin: coinType, account: 0)
    } else {
      return CNBBaseCoin(purpose: .BIP49, coin: coinType, account: 0)
    }
  }

}
