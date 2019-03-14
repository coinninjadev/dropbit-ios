//
//  CKMAddressTransactionSummary+CoreDataClass.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import os.log

@objc(CKMAddressTransactionSummary)
public class CKMAddressTransactionSummary: NSManagedObject {

  static func findAll(in context: NSManagedObjectContext) -> [CKMAddressTransactionSummary] {
    let fetchRequest: NSFetchRequest<CKMAddressTransactionSummary> = CKMAddressTransactionSummary.fetchRequest()

    var result: [CKMAddressTransactionSummary] = []
    context.performAndWait {
      do {
        result = try context.fetch(fetchRequest)
      } catch {
        result = []
      }
    }
    return result
  }

  static func findAll(
    byATSResponses responses: [AddressTransactionSummaryResponse],
    in context: NSManagedObjectContext
    ) -> [CKMAddressTransactionSummary] {

    var result: [CKMAddressTransactionSummary] = []

    context.performAndWait {
      let fetchRequest: NSFetchRequest<CKMAddressTransactionSummary> = CKMAddressTransactionSummary.fetchRequest()
      do {
        let all = try context.fetch(fetchRequest)
        let filtered = responses.compactMap { response in all.first { $0.txid == response.txid && $0.addressId == response.address } }
        result = filtered
      } catch {
        result = []
      }
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

    context.performAndWait {
      do {
        if let summary = try context.fetch(fetchRequest).first {
          addressTransactionSummary = summary
        } else {
          addressTransactionSummary = CKMAddressTransactionSummary(insertInto: context)
          addressTransactionSummary.configure(with: response, in: context)
        }
      } catch {
        addressTransactionSummary = CKMAddressTransactionSummary(insertInto: context)
        addressTransactionSummary.configure(with: response, in: context)
      }
    }

    return addressTransactionSummary
  }

  static func find(by txid: String, in context: NSManagedObjectContext) -> [CKMAddressTransactionSummary] {
    let fetchRequest: NSFetchRequest<CKMAddressTransactionSummary> = CKMAddressTransactionSummary.fetchRequest()
    let keyPath = #keyPath(CKMAddressTransactionSummary.txid)
    fetchRequest.predicate = NSPredicate(format: "\(keyPath) = %@", txid)

    var items: [CKMAddressTransactionSummary] = []
    do {
      items = try context.fetch(fetchRequest)
    } catch {
      let logger = OSLog(subsystem: "com.coinninja.coinkeeper.ckmaddresstransactionsummary", category: "CKMAddressTransactionSummary")
      os_log("Could not execute fetch request for AddressTransactionSummary objects: %@", log: logger, type: .error, error.localizedDescription)
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
      let logger = OSLog(subsystem: "com.coinninja.coinkeeper.ckmaddresstransactionsummary", category: "CKMAddressTransactionSummary")
      os_log("Could not execute fetch request for latest AddressTransactionSummary: %@", log: logger, type: .error, error.localizedDescription)
      return nil
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
      txid.map { self.transaction = CKMTransaction.find(byTxid: $0, in: context) }
    }
  }

  var netAmount: Int {
    return received - sent
  }
}
