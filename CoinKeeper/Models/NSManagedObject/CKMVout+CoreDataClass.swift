//
//  CKMVout+CoreDataClass.swift
//  CoinKeeper
//
//  Created by BJ Miller on 5/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import CNBitcoinKit

@objc(CKMVout)
public class CKMVout: NSManagedObject {

  /// findOrCreate a CKMVout
  ///
  /// - Parameters:
  ///   - response: the nexted TransactionVoutResponse inside a TransactionResponse
  ///   - context: a core data context within which to work
  ///   - fullSync: a parameter to indicate if the vout should be reconfigured regardless if it has been configured already
  /// - Returns: an optional CKMVout. This will only be optional if the `txid` property in the TransactionVoutResponse is nil.
  static func findOrCreate(with response: TransactionVoutResponse, in context: NSManagedObjectContext, fullSync: Bool) -> CKMVout? {

    let fetchRequest: NSFetchRequest<CKMVout> = CKMVout.fetchRequest()
    fetchRequest.fetchLimit = 1

    var vout: CKMVout!
    context.performAndWait {
      do {
        fetchRequest.predicate = try CKPredicate.Vout.matching(response: response)
        if let foundVout = try context.fetch(fetchRequest).first {
          vout = foundVout
          if fullSync {
            vout.configure(with: response, in: context)
          }
        } else {
          vout = CKMVout(insertInto: context)
          vout.configure(with: response, in: context)
        }
      } catch {
        // nil
      }
    }

    return vout
  }

  static func findOrCreateTemporaryVout(
    in context: NSManagedObjectContext,
    with transactionData: CNBTransactionData,
    metadata: CNBTransactionMetadata) throws -> CKMVout {

    let changeAddressKeyPath = #keyPath(CNBTransactionMetadata.changeAddress).description
    let changePathKeyPath = #keyPath(CNBTransactionMetadata.changePath).description
    let voutIndexKeyPath = #keyPath(CNBTransactionMetadata.voutIndex).description

    guard let changeAddress = metadata.changeAddress else { throw CKPersistenceError.missingValue(key: changeAddressKeyPath) }
    guard let path = metadata.changePath else { throw CKPersistenceError.missingValue(key: changePathKeyPath) }
    guard let index = metadata.voutIndex else { throw CKPersistenceError.missingValue(key: voutIndexKeyPath) }

    let fetchRequest: NSFetchRequest<CKMVout> = CKMVout.fetchRequest()
    fetchRequest.predicate = CKPredicate.Vout.matching(txid: metadata.txid, index: index.intValue)
    fetchRequest.fetchLimit = 1

    let configureVout: (CKMVout) -> CKMVout = { returnVout in
      returnVout.addressIDs = [changeAddress]
      returnVout.amount = Int(transactionData.changeAmount)
      returnVout.index = index.intValue
      returnVout.isSpent = false
      returnVout.txid = metadata.txid

      let relatedAddress = CKMAddress.findOrCreate(withAddress: changeAddress, derivativePath: path, in: context)
      // set relationships both ways as a query may happen before context is saved
      returnVout.address = relatedAddress
      relatedAddress.vouts.insert(returnVout)

      return returnVout
    }

    var vout: CKMVout!
    do {
      if let foundVout = try context.fetch(fetchRequest).first {
        vout = foundVout
      } else {
        vout = CKMVout(insertInto: context)
      }
    } catch {
      vout = CKMVout(insertInto: context)
    }

    vout = configureVout(vout)

    return vout
  }

  func configure(with voutResponse: TransactionVoutResponse, in context: NSManagedObjectContext) {
    amount = voutResponse.value
    index = voutResponse.n
    addressIDs = voutResponse.addresses
    txid = voutResponse.txid

    let addressFetchRequest: NSFetchRequest<CKMAddress> = CKMAddress.fetchRequest()
    let addressKeyPath = #keyPath(CKMAddress.addressId)
    let addressPredicate = NSPredicate(format: "%K IN %@", addressKeyPath, addressIDs)
    addressFetchRequest.predicate = addressPredicate
    addressFetchRequest.fetchLimit = 1

    context.performAndWait {
      do {
        self.address = try context.fetch(addressFetchRequest).first
        self.isSpent = false // will be re-evaluated later
      } catch {
        self.address = nil
      }
    }
  }

  static func find(from utxo: CNBUnspentTransactionOutput, in context: NSManagedObjectContext) -> CKMVout? {
    let voutFetchRequest: NSFetchRequest<CKMVout> = CKMVout.fetchRequest()
    let txidKeyPath = #keyPath(CKMVout.transaction.txid)
    let indexKeyPath = #keyPath(CKMVout.index)
    let desiredTxid = utxo.txId
    let desiredIndex = Int(utxo.index)
    let txidPredicate = NSPredicate(format: "\(txidKeyPath) = %@", desiredTxid)
    let indexPredicate = NSPredicate(format: "\(indexKeyPath) = %d", desiredIndex)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [txidPredicate, indexPredicate])
    voutFetchRequest.predicate = predicate
    voutFetchRequest.fetchLimit = 1

    var result: CKMVout?
    context.performAndWait {
      do {
        result = try context.fetch(voutFetchRequest).first
      } catch {
        result = nil
      }
    }
    return result
  }

  static func findAll(in context: NSManagedObjectContext) -> [CKMVout] {
    let request: NSFetchRequest<CKMVout> = CKMVout.fetchRequest()
    var result: [CKMVout] = []
    context.performAndWait {
      do {
        result = try context.fetch(request)
      } catch {
        result = []
      }
    }
    return result
  }

  static func findAllSpendable(minAmount: Int, in context: NSManagedObjectContext) -> [CKMVout] {
    let fetchRequest: NSFetchRequest<CKMVout> = CKMVout.fetchRequest()
    fetchRequest.predicate = CKPredicate.Vout.isSpendable(minAmount: minAmount)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(CKMVout.transaction.confirmations), ascending: false)]
    return (try? context.fetch(fetchRequest)) ?? []
  }

  static func findAllUnspent(in context: NSManagedObjectContext) throws -> [CKMVout] {
    let fetchRequest: NSFetchRequest<CKMVout> = CKMVout.fetchRequest()
    fetchRequest.predicate = CKPredicate.Vout.isSpent(value: false)

    var unspentVouts: [CKMVout] = []
    do {
      unspentVouts = try context.fetch(fetchRequest)
    } catch {
      throw SpendableBalanceError.voutFetchFailed
    }

    return unspentVouts
  }

  public override var debugDescription: String {
    struct EncodableCKMVout: Encodable {
      let amount: Int
      let index: Int
      let isSpent: Bool
      let txid: String
      let address: String
    }
    let encodable = EncodableCKMVout(
      amount: self.amount,
      index: self.index,
      isSpent: self.isSpent,
      txid: self.txid ?? "",
      address: self.address?.addressId ?? ""
    )
    let data = try? JSONEncoder().encode(encodable)
    return data.map { String(data: $0, encoding: .utf8) ?? "" } ?? ""
  }

}
