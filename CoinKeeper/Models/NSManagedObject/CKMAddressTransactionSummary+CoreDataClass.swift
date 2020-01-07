//
//  CKMAddressTransactionSummary+CoreDataClass.swift
//  DropBit
//
//  Created by BJ Miller on 4/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import Cnlib

@objc(CKMAddressTransactionSummary)
public class CKMAddressTransactionSummary: NSManagedObject {

  static func findAll(in context: NSManagedObjectContext) -> [CKMAddressTransactionSummary] {
    let fetchRequest: NSFetchRequest<CKMAddressTransactionSummary> = CKMAddressTransactionSummary.fetchRequest()

    var result: [CKMAddressTransactionSummary] = []
    do {
      result = try context.fetch(fetchRequest)
    } catch {
      result = []
    }
    return result
  }

  static func findOrCreate(
    with response: AddressTransactionSummaryResponse,
    in context: NSManagedObjectContext
    ) -> CKMAddressTransactionSummary {

    let keyPath = #keyPath(CKMAddressTransactionSummary.addressId)
    let addressPredicate = NSPredicate(format: "\(keyPath) = %@", response.address)
    let txidKeyPath = #keyPath(CKMAddressTransactionSummary.txid)
    let txidPredicate = NSPredicate(format: "\(txidKeyPath) = %@", response.txid)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [addressPredicate, txidPredicate])
    let fetchRequest = NSFetchRequest<CKMAddressTransactionSummary>(entityName: entityName())
    fetchRequest.fetchLimit = 1
    fetchRequest.predicate = predicate

    var addressTransactionSummary: CKMAddressTransactionSummary!

    do {
      if let summary = try context.fetch(fetchRequest).first {
        addressTransactionSummary = summary
      } else {
        addressTransactionSummary = CKMAddressTransactionSummary(insertInto: context)
      }
    } catch {
      addressTransactionSummary = CKMAddressTransactionSummary(insertInto: context)
    }
    addressTransactionSummary.configure(with: response, in: context)

    return addressTransactionSummary
  }

  static func find(byTxid txid: String, in context: NSManagedObjectContext) -> [CKMAddressTransactionSummary] {
    let fetchRequest: NSFetchRequest<CKMAddressTransactionSummary> = CKMAddressTransactionSummary.fetchRequest()
    fetchRequest.predicate = CKPredicate.AddressTransactionSummary.matching(txid: txid)

    var items: [CKMAddressTransactionSummary] = []
    do {
      items = try context.fetch(fetchRequest)
    } catch {
      log.error(error, message: "Could not execute fetch request for AddressTransactionSummary objects")
    }
    return items
  }

  static func findLatest(in context: NSManagedObjectContext) -> CKMAddressTransactionSummary? {
    let datePath = #keyPath(CKMAddressTransactionSummary.transaction.date)
    let fetchRequest: NSFetchRequest<CKMAddressTransactionSummary> = CKMAddressTransactionSummary.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: datePath, ascending: false)]
    fetchRequest.fetchLimit = 1

    do {
      return try context.fetch(fetchRequest).first
    } catch {
      log.error(error, message: "Could not execute fetch request for latest AddressTransactionSummary")
      return nil
    }
  }

  static func findAllTxids(in context: NSManagedObjectContext) -> [String] {
    return findAll(in: context).map { $0.txid }
  }

  static func findAll(matching coin: CNBCnlibBaseCoin, in context: NSManagedObjectContext) -> [CKMAddressTransactionSummary] {
    let fetchRequest: NSFetchRequest<CKMAddressTransactionSummary> = CKMAddressTransactionSummary.fetchRequest()
    fetchRequest.predicate = CKPredicate.AddressTransactionSummary.matching(coin: coin)
    do {
      return try context.fetch(fetchRequest)
    } catch {
      log.error(error, message: "Could not execute fetch request for latest AddressTransactionSummary")
      return []
    }
  }

  func configure(
    with response: AddressTransactionSummaryResponse,
    in context: NSManagedObjectContext
    ) {

    address = CKMAddress.findOrCreate(withAddress: response.address, in: context)
    if address?.derivativePath == nil, let path = response.derivativePathResponse {
      let derivativePath = CKMDerivativePath.findOrCreate(with: path, in: context)
      address?.derivativePath = derivativePath
    }
    txid = response.txid
    addressId = response.address
    sent = response.vin
    received = response.vout

    if wallet == nil {
      wallet = CKMWallet.find(in: context)
    }

    if transaction == nil {
      self.transaction = CKMTransaction.find(byTxid: txid, in: context)
    }
  }

  var netAmount: Int {
    return received - sent
  }
}
