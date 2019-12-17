//
//  MockAddressDataSource.swift
//  DropBit
//
//  Created by Ben Winters on 9/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import Cnlib

class MockAddressDataSource: AddressDataSourceType {

  func receiveAddressesUpToMaxUsed(in context: NSManagedObjectContext) -> [String] {
    return []
  }

  func changeAddressesUpToMaxUsed(in context: NSManagedObjectContext) -> [String] {
    return []
  }

  var receiveAddressValue: CNBCnlibMetaAddress!
  func receiveAddress(at index: Int) -> CNBCnlibMetaAddress {
    return receiveAddressValue
  }

  var changeAddressValue: CNBCnlibMetaAddress!
  func changeAddress(at index: Int) -> CNBCnlibMetaAddress {
    return changeAddressValue
  }

  var nextChangeAddressValue: CNBCnlibMetaAddress!
  func nextChangeAddress(in context: NSManagedObjectContext) -> CNBCnlibMetaAddress {
    return nextChangeAddressValue
  }

  var validAddresses: [String] = []
  func checkAddressExists(for address: String, in context: NSManagedObjectContext) throws -> CNBCnlibMetaAddress {
    if validAddresses.contains(address) {
      return CNBCnlibMetaAddress(address, path: nil, uncompressedPublicKey: nil)
    } else {
      return nil
    }
  }

  func nextAvailableReceiveAddresses(number: Int,
                                     forServerPool: Bool,
                                     indicesToSkip: Set<Int>,
                                     in context: NSManagedObjectContext) -> [CNBCnlibMetaAddress] {
    return []
  }

  func nextAvailableReceiveAddress(forServerPool: Bool,
                                   indicesToSkip: Set<Int>,
                                   in context: NSManagedObjectContext) -> CNBCnlibMetaAddress? {
    return nil
  }

  func lastReceiveIndex(in context: NSManagedObjectContext) -> Int? {
    return nil
  }

  func lastChangeIndex(in context: NSManagedObjectContext) -> Int? {
    return nil
  }

}
