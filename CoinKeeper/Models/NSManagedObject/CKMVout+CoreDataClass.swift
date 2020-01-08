//
//  CKMVout+CoreDataClass.swift
//  DropBit
//
//  Created by BJ Miller on 5/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import Cnlib

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

    return vout
  }

  static func findOrCreateTemporaryVout(
    in context: NSManagedObjectContext,
    with transactionData: CNBCnlibTransactionData,
    metadata: CNBCnlibTransactionMetadata) throws -> CKMVout {

    let changeAddressKeyPath = #keyPath(CNBCnlibTransactionMetadata.transactionChangeMetadata.address).description
    let changePathKeyPath = #keyPath(CNBCnlibTransactionMetadata.transactionChangeMetadata.path).description
    let voutIndexKeyPath = #keyPath(CNBCnlibTransactionMetadata.transactionChangeMetadata.voutIndex).description

    let changeMetadata = metadata.transactionChangeMetadata
    guard let changeAddress = changeMetadata?.address else { throw CKPersistenceError.missingValue(key: changeAddressKeyPath) }
    guard let path = changeMetadata?.path else { throw CKPersistenceError.missingValue(key: changePathKeyPath) }
    guard let index = changeMetadata?.voutIndex else { throw CKPersistenceError.missingValue(key: voutIndexKeyPath) }

    let fetchRequest: NSFetchRequest<CKMVout> = CKMVout.fetchRequest()
    fetchRequest.predicate = CKPredicate.Vout.matching(txid: metadata.txid, index: index)
    fetchRequest.fetchLimit = 1

    let configureVout: (CKMVout) -> CKMVout = { returnVout in
      returnVout.addressIDs = [changeAddress]
      returnVout.amount = Int(transactionData.changeAmount)
      returnVout.index = index
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

    do {
      self.address = try context.fetch(addressFetchRequest).first
      self.isSpent = false // will be re-evaluated later
    } catch {
      self.address = nil
    }
  }

  static func find(from utxo: CNBCnlibUTXO, in context: NSManagedObjectContext) -> CKMVout? {
    let voutFetchRequest: NSFetchRequest<CKMVout> = CKMVout.fetchRequest()
    let txidKeyPath = #keyPath(CKMVout.transaction.txid)
    let indexKeyPath = #keyPath(CKMVout.index)
    let desiredTxid = utxo.txid
    let desiredIndex = Int(utxo.index)
    let txidPredicate = NSPredicate(format: "\(txidKeyPath) = %@", desiredTxid)
    let indexPredicate = NSPredicate(format: "\(indexKeyPath) = %d", desiredIndex)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [txidPredicate, indexPredicate])
    voutFetchRequest.predicate = predicate
    voutFetchRequest.fetchLimit = 1

    var result: CKMVout?
    do {
      result = try context.fetch(voutFetchRequest).first
    } catch {
      result = nil
    }
    return result
  }

  static func findUTXOs(from transactionData: CNBCnlibTransactionData, in context: NSManagedObjectContext) -> [CKMVout] {
    let len = transactionData.utxoCount()
    return (0..<len)
      .compactMap { try? transactionData.requiredUTXO(at: $0) } // no need to try/catch, errors are bounds checking only
      .compactMap { CKMVout.find(from: $0, in: context) }
  }

  static func findAllSpendable(minAmount: Int, in context: NSManagedObjectContext) -> [CKMVout] {
    let fetchRequest: NSFetchRequest<CKMVout> = CKMVout.fetchRequest()
    fetchRequest.predicate = CKPredicate.Vout.isSpendable(minAmount: minAmount)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(CKMVout.transaction.confirmations), ascending: false)]
    return (try? context.fetch(fetchRequest)) ?? []
  }

  static func findAllUnspent(in context: NSManagedObjectContext) throws -> [CKMVout] {
    let fetchRequest: NSFetchRequest<CKMVout> = CKMVout.fetchRequest()
    fetchRequest.predicate = CKPredicate.Vout.isSpendable(minAmount: 0, minReceiveConfirmations: 0)

    var unspentVouts: [CKMVout] = []
    do {
      unspentVouts = try context.fetch(fetchRequest)
    } catch {
      throw SpendableBalanceError.voutFetchFailed
    }

    return unspentVouts
  }

  static func unspentBalance(in context: NSManagedObjectContext) -> Int {
    do {
      let unspent = try findAllUnspent(in: context)
      let total = unspent.reduce(0) { $0 + $1.amount }
      return total
    } catch {
      return 0
    }
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
