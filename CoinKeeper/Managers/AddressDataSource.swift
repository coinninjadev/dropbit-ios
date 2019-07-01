//
//  AddressDataSource.swift
//  DropBit
//
//  Created by Ben Winters on 9/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import PromiseKit

protocol AddressDataSourceType: AnyObject {

  func receiveAddress(at index: Int) -> CNBMetaAddress
  func changeAddress(at index: Int) -> CNBMetaAddress

  func nextChangeAddress(in context: NSManagedObjectContext) -> CNBMetaAddress

  func checkAddressExists(for address: String, in context: NSManagedObjectContext) -> CNBAddressResult?

  /**
   Returns an array of addresses that are neither used nor currently on the server, matching the count parameter.
   - param forServerPool: Should be true when getting new addresses to add to the server pool.
   */
  func nextAvailableReceiveAddresses(number: Int,
                                     forServerPool: Bool,
                                     indicesToSkip: Set<Int>,
                                     in context: NSManagedObjectContext) -> [CNBMetaAddress]
  func nextAvailableReceiveAddress(forServerPool: Bool,
                                   indicesToSkip: Set<Int>,
                                   in context: NSManagedObjectContext) -> CNBMetaAddress?

  func lastReceiveIndex(in context: NSManagedObjectContext) -> Int?
  func lastChangeIndex(in context: NSManagedObjectContext) -> Int?

  func receiveAddressesUpToMaxUsed(in context: NSManagedObjectContext) -> [String]
  func changeAddressesUpToMaxUsed(in context: NSManagedObjectContext) -> [String]
}

/**
 Responsible for providing addresses and indexes according to various constraints for the given wallet.
 */
class AddressDataSource: AddressDataSourceType {

  private let wallet: CNBHDWallet
  private unowned let persistenceManager: PersistenceManagerType

  private let gapLimit = 20

  init(wallet: CNBHDWallet, persistenceManager: PersistenceManagerType) {
    self.wallet = wallet
    self.persistenceManager = persistenceManager
  }

  func receiveAddress(at index: Int) -> CNBMetaAddress {
    return wallet.receiveAddress(for: UInt(index))
  }

  func changeAddress(at index: Int) -> CNBMetaAddress {
    return wallet.changeAddress(for: UInt(index))
  }

  func nextChangeAddress(in context: NSManagedObjectContext) -> CNBMetaAddress {
    let lastIndex = persistenceManager.brokers.wallet.lastChangeAddressIndex(in: context) ?? -1
    let nextChangeIndex = lastIndex + 1
    return changeAddress(at: nextChangeIndex)
  }

  func lastReceiveIndex(in context: NSManagedObjectContext) -> Int? {
    return persistenceManager.brokers.wallet.lastReceiveAddressIndex(in: context)
  }

  func lastChangeIndex(in context: NSManagedObjectContext) -> Int? {
    return persistenceManager.brokers.wallet.lastChangeAddressIndex(in: context)
  }

  func checkAddressExists(for address: String, in context: NSManagedObjectContext) -> CNBAddressResult? {
    let lastRecIdx = lastReceiveIndex(in: context) ?? -1
    let lastChgIdx = lastChangeIndex(in: context) ?? -1
    let lastIndex = max(lastRecIdx, lastChgIdx)
    return wallet.check(forAddress: address, upTo: lastIndex + gapLimit)
  }

  func nextAvailableReceiveAddress(forServerPool: Bool, indicesToSkip: Set<Int> = [], in context: NSManagedObjectContext) -> CNBMetaAddress? {
    return nextAvailableReceiveAddresses(number: 1, forServerPool: forServerPool, indicesToSkip: indicesToSkip, in: context).first
  }

  func nextAvailableReceiveAddresses(number: Int,
                                     forServerPool: Bool,
                                     indicesToSkip: Set<Int> = [],
                                     in context: NSManagedObjectContext) -> [CNBMetaAddress] {
    guard number > 0 else { return [] }

    // A set of indices that have been deemed unusable by internal functions.
    var localIndicesToSkip = indicesToSkip

    if forServerPool {
      localIndicesToSkip = persistenceManager.brokers.user.serverPoolAddresses(in: context).compactMap { $0.derivativePath?.index }.asSet()
    }

    let pendingDropBitAddresses: [String] = persistenceManager.brokers.invitation.addressesProvidedForReceivedPendingDropBits(in: context)

    let startIndex = (lastReceiveIndex(in: context) ?? -1) + 1
    let endIndex = startIndex + 20
    let futureAddressIndices = (startIndex..<endIndex).map { Int($0) }
    let remainingGapIndices = persistenceManager.brokers.wallet.receiveAddressIndexGaps
      .subtracting(localIndicesToSkip).asArray()
      .filter { $0 < startIndex }
      .sorted()

    let usableIndices = remainingGapIndices + futureAddressIndices

    let usableMetaAddresses = usableIndices
      .filter { !localIndicesToSkip.contains($0) }
      .map { self.receiveAddress(at: $0) }
      .filter { !pendingDropBitAddresses.contains($0.address) }

    let targetIndex = number - 1
    let returnableMetaAddresses = usableMetaAddresses.prefix(through: targetIndex).map { $0 }

    return returnableMetaAddresses
  }

  func nextAvailableReceiveIndex(indicesToSkip: Set<Int>, in context: NSManagedObjectContext) -> Int {
    let next = nextAvailableReceiveAddress(forServerPool: false, indicesToSkip: indicesToSkip, in: context)?.derivationPath.index ?? UInt(0)
    return Int(next)
  }

  func receiveAddressesUpToMaxUsed(in context: NSManagedObjectContext) -> [String] {
    let max = (self.lastReceiveIndex(in: context) ?? -1) + gapLimit
    return (0...max).map(receiveAddress).map { $0.address }
  }

  func changeAddressesUpToMaxUsed(in context: NSManagedObjectContext) -> [String] {
    let max = (self.lastChangeIndex(in: context) ?? -1) + gapLimit
    return (0...max).map(changeAddress).map { $0.address }
  }
}
