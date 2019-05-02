//
//  MockAddressDataSource.swift
//  DropBit
//
//  Created by Ben Winters on 9/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import CNBitcoinKit

class MockAddressDataSource: AddressDataSourceType {

  func receiveAddressesUpToMaxUsed(in context: NSManagedObjectContext) -> [String] {
    return []
  }

  func changeAddressesUpToMaxUsed(in context: NSManagedObjectContext) -> [String] {
    return []
  }

  var receiveAddressValue: CNBMetaAddress!
  func receiveAddress(at index: Int) -> CNBMetaAddress {
    return receiveAddressValue
  }

  var changeAddressValue: CNBMetaAddress!
  func changeAddress(at index: Int) -> CNBMetaAddress {
    return changeAddressValue
  }

  var nextChangeAddressValue: CNBMetaAddress!
  func nextChangeAddress(in context: NSManagedObjectContext) -> CNBMetaAddress {
    return nextChangeAddressValue
  }

  var validAddresses: [String] = []
  func checkAddressExists(for address: String, in context: NSManagedObjectContext) -> CNBAddressResult? {
    if validAddresses.contains(address) {
      return CNBAddressResult(address: address, isReceiveAddress: true)
    } else {
      return nil
    }
  }

  func nextAvailableReceiveAddresses(number: Int,
                                     forServerPool: Bool,
                                     indicesToSkip: Set<Int>,
                                     in context: NSManagedObjectContext) -> [CNBMetaAddress] {
    return []
  }

  func nextAvailableReceiveAddress(forServerPool: Bool,
                                   indicesToSkip: Set<Int>,
                                   in context: NSManagedObjectContext) -> CNBMetaAddress? {
    return nil
  }

  func lastReceiveIndex(in context: NSManagedObjectContext) -> Int? {
    return nil
  }

  func lastChangeIndex(in context: NSManagedObjectContext) -> Int? {
    return nil
  }

}
