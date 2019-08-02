//
//  CKMVin+CoreDataClass.swift
//  CoinKeeper
//
//  Created by BJ Miller on 5/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CKMVin)
public class CKMVin: NSManagedObject {

  static let coinbasePrefix = "Coinbase_"

  static func findOrCreate(
    with response: TransactionVinResponse,
    newTxid: String,
    in context: NSManagedObjectContext,
    fullSync: Bool) -> CKMVin {

    let fetchRequest: NSFetchRequest<CKMVin> = CKMVin.fetchRequest()
    fetchRequest.predicate = CKPredicate.Vin.matching(response: response)
    fetchRequest.fetchLimit = 1

    var vin: CKMVin!
    context.performAndWait {
      do {
        if let foundVin = try context.fetch(fetchRequest).first {
          vin = foundVin
          if fullSync {
            vin.configure(with: response, newTxid: newTxid, in: context)
          }
        } else {
          vin = CKMVin(insertInto: context)
          vin.configure(with: response, newTxid: newTxid, in: context)
        }
      } catch {
        vin = CKMVin(insertInto: context)
        vin.configure(with: response, newTxid: newTxid, in: context)
      }
    }

    return vin
  }

  func configure(with vinResponse: TransactionVinResponse, newTxid: String, in context: NSManagedObjectContext) {
    let transactionIsCoinbase = vinResponse.txid.filter { $0 != "0" }.isEmpty
    if transactionIsCoinbase {
      previousTxid = CKMVin.coinbasePrefix + newTxid
    } else {
      previousTxid = vinResponse.txid
    }
    previousVoutIndex = vinResponse.vout
    amount = vinResponse.value
    addressIDs = vinResponse.addresses
    updateBelongsToWallet(with: vinResponse.addresses, in: context)
  }

  /// Update `belongsToWallet` property. Passes `addressIDs` property to similar `updateBelongsToWallet` method.
  ///
  /// - Parameter context: a Managed Object Context within which to work
  func updateBelongsToWallet(in context: NSManagedObjectContext) {
    self.updateBelongsToWallet(with: addressIDs, in: context)
  }

  /// Update `belongsToWallet` property with a [String] passed in.
  ///
  /// - Parameters:
  ///   - addresses: an array of addresses as [String]
  ///   - context: a Managed Object Context within which to work
  func updateBelongsToWallet(with addresses: [String], in context: NSManagedObjectContext) {
    let foundAddress = addresses.compactMap { CKMAddress.find(withAddress: $0, in: context) }
    belongsToWallet = foundAddress.isNotEmpty
  }

}
