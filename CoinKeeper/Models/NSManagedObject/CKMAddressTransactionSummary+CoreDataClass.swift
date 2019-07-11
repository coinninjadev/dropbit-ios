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
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CKMAddressTransactionSummary.entityName())
    let txidKey = #keyPath(CKMAddressTransactionSummary.txid)
    fetchRequest.propertiesToFetch = [txidKey]
    fetchRequest.resultType = .dictionaryResultType
    do {
      guard let results = try context.fetch(fetchRequest) as? [[String: String]] else {
        log.error("Could not cast results to [[String: String]] for AddressTransactionSummary.findAllTxids")
        return []
      }

      return results.compactMap { $0[txidKey] }

    } catch {
      log.error(error, message: "Could not execute fetch request for AddressTransactionSummary.findAllTxids")
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
