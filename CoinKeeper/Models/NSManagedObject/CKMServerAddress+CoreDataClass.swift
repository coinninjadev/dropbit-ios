//
//  CKMServerAddress+CoreDataClass.swift
//  DropBit
//
//  Created by Ben Winters on 5/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CKMServerAddress)
public class CKMServerAddress: NSManagedObject {

  public convenience init(address: String, createdAt: Date, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.address = address
    self.createdAt = createdAt
  }

  static func find(withAddressId addressId: String, in context: NSManagedObjectContext) -> CKMServerAddress? {
    let fetchRequest: NSFetchRequest<CKMServerAddress> = CKMServerAddress.fetchRequest()
    let path = #keyPath(CKMServerAddress.address)
    fetchRequest.predicate = NSPredicate(format: "\(path) == %@", addressId)
    fetchRequest.fetchLimit = 1

    var ckmServerAddress: CKMServerAddress?
    context.performAndWait {
      do {
        ckmServerAddress = try context.fetch(fetchRequest).first
      } catch {
        ckmServerAddress = nil
      }
    }
    return ckmServerAddress
  }

  static func findAll(in context: NSManagedObjectContext) -> [CKMServerAddress] {
    let fetchRequest: NSFetchRequest<CKMServerAddress> = CKMServerAddress.fetchRequest()

    return fetchServerAddresses(from: fetchRequest, in: context)
  }

  static func maxIndex(in context: NSManagedObjectContext) -> Int? {
    let serverAddresses = findAll(in: context)
    return serverAddresses.compactMap { $0.derivativePath?.index }.max()
  }

  static func find(matchingAddresses addresses: [CKMAddress], in context: NSManagedObjectContext) -> [CKMServerAddress] {
    let addressIds = addresses.map { $0.addressId }
    let fetchRequest: NSFetchRequest<CKMServerAddress> = CKMServerAddress.fetchRequest()
    let path = #keyPath(CKMServerAddress.address)
    fetchRequest.predicate = NSPredicate(format: "\(path) IN %@", addressIds)

    return fetchServerAddresses(from: fetchRequest, in: context)
  }

  static func find(notMatchingAddressIds addressIds: [String], in context: NSManagedObjectContext) -> [CKMServerAddress] {
    let fetchRequest: NSFetchRequest<CKMServerAddress> = CKMServerAddress.fetchRequest()
    let path = #keyPath(CKMServerAddress.address)
    fetchRequest.predicate = NSPredicate(format: "NOT (\(path) IN %@)", addressIds)

    return fetchServerAddresses(from: fetchRequest, in: context)
  }

  private static func fetchServerAddresses(
    from fetchRequest: NSFetchRequest<CKMServerAddress>,
    in context: NSManagedObjectContext
    ) -> [CKMServerAddress] {

    var result: [CKMServerAddress] = []
    context.performAndWait {
      do {
        result = try context.fetch(fetchRequest)
      } catch {
        result = []
      }
    }
    return result
  }
}
