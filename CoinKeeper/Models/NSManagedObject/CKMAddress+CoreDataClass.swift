//
//  CKMAddress+CoreDataClass.swift
//  DropBit
//
//  Created by Ben Winters on 4/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import Cnlib

/**
 An address owned by the owner of this Bitcoin wallet.
 */
@objc(CKMAddress)
public class CKMAddress: NSManagedObject {

  public override func awakeFromInsert() {
    super.awakeFromInsert()
    setPrimitiveValue("", forKey: #keyPath(CKMAddress.addressId))
  }

  public convenience init(address: String, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.addressId = address
    self.setVoutRelationshipIfAny(in: context)
  }

  static func findOrCreate(
    withAddress address: String,
    derivativePath path: CNBCnlibDerivationPath,
    in context: NSManagedObjectContext) -> CKMAddress {
    let address = CKMAddress.findOrCreate(withAddress: address, in: context)
    if address.derivativePath == nil {
      let newPath = CKMDerivativePath.findOrCreate(with: path.purpose, path.coin, path.account, path.change, path.index, in: context)

      // set relationship both ways, as save operation may not happen before query is executed on addresses
      address.derivativePath = newPath
      newPath.address = address
    }
    return address
  }

  static func findOrCreate(withAddress address: String, in context: NSManagedObjectContext) -> CKMAddress {
    var ckmAddress: CKMAddress!
    if let foundAddress = find(withAddress: address, in: context) {
      ckmAddress = foundAddress
    } else {
      ckmAddress = CKMAddress(address: address, insertInto: context)
    }
    return ckmAddress
  }

  static func find(withAddress address: String, in context: NSManagedObjectContext) -> CKMAddress? {
    let fetchRequest: NSFetchRequest<CKMAddress> = CKMAddress.fetchRequest()
    let path = #keyPath(CKMAddress.addressId)
    fetchRequest.predicate = NSPredicate(format: "\(path) == %@", address)
    fetchRequest.fetchLimit = 1

    var ckmAddress: CKMAddress?
    do {
      ckmAddress = try context.fetch(fetchRequest).first
    } catch {
      ckmAddress = nil
    }
    return ckmAddress
  }

  static func find(withAddresses addresses: [String], in context: NSManagedObjectContext) -> [CKMAddress] {
    let fetchRequest: NSFetchRequest<CKMAddress> = CKMAddress.fetchRequest()
    fetchRequest.predicate = CKPredicate.Address.relatedTo(addresses: addresses)

    do {
      return try context.fetch(fetchRequest)
    } catch {
      return []
    }
  }

  private func setVoutRelationshipIfAny(in context: NSManagedObjectContext) {
    let voutFetchRequest: NSFetchRequest<CKMVout> = CKMVout.fetchRequest()

    do {
      let voutsArray = try context.fetch(voutFetchRequest)
      let filteredVouts = voutsArray.filter { $0.addressIDs.contains(addressId) }
      let voutsSet = Set(filteredVouts)
      self.addToVouts(voutsSet)
    } catch {
      log.error(error, message: "Failed to fetch utxos")
    }
  }

  var isChangeAddress: Bool {
    guard let path = derivativePath else { return false }
    return path.change == CKMDerivativePath.changeIsChangeValue
  }

  var isReceiveAddress: Bool {
    guard let path = derivativePath else { return false }
    return path.change == CKMDerivativePath.changeIsReceiveValue
  }
}
