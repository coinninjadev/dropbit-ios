//
//  CKMDerivativePath+CoreDataClass.swift
//  DropBit
//
//  Created by BJ Miller on 4/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import CNBitcoinKit

@objc(CKMDerivativePath)
public class CKMDerivativePath: NSManagedObject {

  // Constants that describe the `change` property of the derivative path
  static let changeIsReceiveValue = 0
  static let changeIsChangeValue = 1

  static var relevantCoin: Int {
    #if DEBUG
    return Int(CoinType.TestNet.rawValue)
    #else
    return Int(CoinType.MainNet.rawValue)
    #endif
  }

  static func fetchRequest(for fullPath: String) -> NSFetchRequest<CKMDerivativePath> {
    let fullPathKeyPath = #keyPath(CKMDerivativePath.fullPath)
    let predicate = NSPredicate(format: "%K = %@", fullPathKeyPath, fullPath)

    let fetchRequest = CKMDerivativePath.fetchRequest() as NSFetchRequest<CKMDerivativePath>
    fetchRequest.fetchLimit = 1
    fetchRequest.predicate = predicate
    return fetchRequest
  }

  //Used for persistence
  static func fullPath(with purpose: Int, _ coin: Int, _ account: Int, _ change: Int, _ index: Int) -> String {
    return "m/\(purpose)/\(coin)/\(account)/\(change)/\(index)"
  }

  //Used for display
  func fullPublicPath() -> String {
    return "M/\(purpose)'/\(coin)'/\(account)'/\(change)/\(index)"
  }

  func asCNBDerivationPath() -> CNBDerivationPath {
    let purpose = CoinDerivation(rawValue: UInt(self.purpose)) ?? CoinDerivation.BIP49
    let coinType = CoinType(rawValue: UInt(self.coin)) ?? CoinType.MainNet
    return CNBDerivationPath(purpose: purpose, coinType: coinType, account: UInt(self.account), change: UInt(self.change), index: UInt(self.index))
  }

  static func findOrCreate(with dpResponse: DerivativePathResponse, in context: NSManagedObjectContext) -> CKMDerivativePath {
    return findOrCreate(
      with: dpResponse.purpose,
      dpResponse.coin,
      dpResponse.account,
      dpResponse.change,
      dpResponse.index,
      in: context)
  }

  static func findAll(in context: NSManagedObjectContext) -> [CKMDerivativePath] {
    let fetchRequest = CKMDerivativePath.fetchRequest() as NSFetchRequest<CKMDerivativePath>
    do {
      return try context.fetch(fetchRequest)
    } catch {
      return []
    }
  }

  static func findOrCreate(withIndex receiveIndex: Int, in context: NSManagedObjectContext) -> CKMDerivativePath {
    return findOrCreate(with: 49, relevantCoin, 0, 0, receiveIndex, in: context)
  }

  static func findOrCreate(
    with purpose: Int,
    _ coin: Int,
    _ account: Int,
    _ change: Int,
    _ index: Int,
    in context: NSManagedObjectContext) -> CKMDerivativePath {

    let fullPath = CKMDerivativePath.fullPath(with: purpose, coin, account, change, index)

    let fetchRequest = CKMDerivativePath.fetchRequest(for: fullPath)

    var derivativePath: CKMDerivativePath!

    do {
      if let path = try context.fetch(fetchRequest).first {
        derivativePath = path
      } else {
        derivativePath = CKMDerivativePath(insertInto: context)
      }
    } catch {
      derivativePath = CKMDerivativePath(insertInto: context)
    }

    derivativePath.purpose = purpose
    derivativePath.coin = coin
    derivativePath.account = account
    derivativePath.change = change
    derivativePath.index = index
    derivativePath.fullPath = fullPath

    return derivativePath
  }

  static func findAllReceivePathsWithAddressTransactionSummaries(in context: NSManagedObjectContext) -> [CKMDerivativePath] {
    let fetchRequest: NSFetchRequest<CKMDerivativePath> = CKMDerivativePath.fetchRequest()
    fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      CKPredicate.DerivativePath.forChangeIndex(changeIsReceiveValue),
      CKPredicate.DerivativePath.withAddressTransactionSummaries(),
      CKPredicate.DerivativePath.withAddress()
      ])
    do {
      return try context.fetch(fetchRequest)
    } catch {
      log.error(error, message: nil)
      return []
    }
  }

  static func maxUsedReceiveIndex(in context: NSManagedObjectContext) -> Int? {
    return maxUsedIndex(forChangeIndex: changeIsReceiveValue, in: context)
  }

  static func maxUsedChangeIndex(in context: NSManagedObjectContext) -> Int? {
    return maxUsedIndex(forChangeIndex: changeIsChangeValue, in: context)
  }

  private static func maxUsedIndex(forChangeIndex change: Int, in context: NSManagedObjectContext) -> Int? {
    let fetchRequest: NSFetchRequest<CKMDerivativePath> = CKMDerivativePath.fetchRequest()
    let changePredicate = CKPredicate.DerivativePath.forChangeIndex(change)
    let nonServerPredicate = CKPredicate.DerivativePath.withoutServerAddress()
    let hasAddressPredicate = CKPredicate.DerivativePath.withAddress()

    fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [changePredicate, nonServerPredicate, hasAddressPredicate])
    fetchRequest.fetchLimit = 1

    let indexKeyPath = #keyPath(CKMDerivativePath.index)
    let indexSortDescriptor = NSSortDescriptor(key: indexKeyPath, ascending: false)
    fetchRequest.sortDescriptors = [indexSortDescriptor]

    var maxIndex: Int?
    context.performAndWait {
      do {
        maxIndex = try context.fetch(fetchRequest).first?.index
      } catch {
        log.error(error, message: nil)
      }
    }
    return maxIndex
  }
}
