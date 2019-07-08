//
//  SharedPayloadManager.swift
//  DropBit
//
//  Created by BJ Miller on 5/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

protocol SharedPayloadManagerType: AnyObject {
  func persistReceivedSharedPayloads(
    _ payloads: [Data],
    hasher: HashingManager,
    contactCacheManager: ContactCacheManagerType,
    in context: NSManagedObjectContext)
}

class SharedPayloadManager: SharedPayloadManagerType {

  struct PayloadPersistenceDependencies {
    let hasher: HashingManager
    let salt: Data
    let contactCacheManager: ContactCacheManagerType
    let context: NSManagedObjectContext
  }

  func persistReceivedSharedPayloads(
    _ payloads: [Data],
    hasher: HashingManager,
    contactCacheManager: ContactCacheManagerType,
    in context: NSManagedObjectContext) {
    let salt: Data
    do {
      salt = try hasher.salt()
    } catch {
      log.error(error, message: "Failed to get salt for hashing shared payload phone number")
      return
    }

    let dependencies = PayloadPersistenceDependencies(
      hasher: hasher,
      salt: salt,
      contactCacheManager: contactCacheManager,
      context: context
    )

    if let v1Payloads = self.payloadsAsV1(from: payloads) {
      self.persistReceivedV1SharedPayloads(v1Payloads, with: dependencies)
    }

    if let v2Payloads = self.payloadsAsV2(from: payloads) {
      self.persistReceivedV2SharedPayloads(v2Payloads, with: dependencies)
    }
  }

  // MARK: private

  private func persistReceivedV1SharedPayloads(_ payloads: [SharedPayloadV1], with deps: PayloadPersistenceDependencies) {

    for payload in payloads {
      guard let tx = CKMTransaction.find(byTxid: payload.txid, in: deps.context) else { continue }

      let memoWasShared = configureTransaction(tx, withMemoIfAppropriate: payload.info.memo)
      let phoneNumber = payload.profile.globalPhoneNumber()
      let phoneNumberHash = deps.hasher.hash(phoneNumber: phoneNumber, salt: deps.salt, parsedNumber: nil)

      if tx.phoneNumber == nil, let inputs = ManagedPhoneNumberInputs(phoneNumber: phoneNumber) {
        tx.phoneNumber = CKMPhoneNumber.findOrCreate(withInputs: inputs,
                                                     phoneNumberHash: phoneNumberHash,
                                                     in: deps.context)

        let counterpartyInputs = deps.contactCacheManager.managedContactComponents(forGlobalPhoneNumber: phoneNumber)?.counterpartyInputs
        if let name = counterpartyInputs?.name {
          tx.phoneNumber?.counterparty = CKMCounterparty.findOrCreate(with: name, in: deps.context)
        }
      }

      let payloadAsData = try? payload.encoded()
      let ckmSharedPayload = CKMTransactionSharedPayload(sharingDesired: memoWasShared,
                                                         fiatAmount: payload.info.amount,
                                                         fiatCurrency: payload.info.currency,
                                                         receivedPayload: payloadAsData,
                                                         insertInto: deps.context)
      tx.sharedPayload = ckmSharedPayload
    }
  }

  private func persistReceivedV2SharedPayloads(_ payloads: [SharedPayloadV2], with deps: PayloadPersistenceDependencies) {

    for payload in payloads {
      guard let tx = CKMTransaction.find(byTxid: payload.txid, in: deps.context) else { continue }

      let memoWasShared = configureTransaction(tx, withMemoIfAppropriate: payload.info.memo)

      guard let profile = payload.profile else { continue }
      switch profile.type {
      case .phone:
        guard let phoneNumber = profile.globalPhoneNumber() else { continue }
        self.configureTransaction(tx, withPhoneNumber: phoneNumber, dependencies: deps)

      case .twitter:
        guard let twitterContact = profile.twitterContact() else { continue }
        if tx.twitterContact == nil {
          tx.twitterContact = CKMTwitterContact.findOrCreate(with: twitterContact, in: deps.context)
        }
      }

      let payloadAsData = try? payload.encoded()
      let ckmSharedPayload = CKMTransactionSharedPayload(sharingDesired: memoWasShared,
                                                         fiatAmount: payload.info.amount,
                                                         fiatCurrency: payload.info.currency,
                                                         receivedPayload: payloadAsData,
                                                         insertInto: deps.context)
      tx.sharedPayload = ckmSharedPayload
    }
  }

  private func configureTransaction(_ tx: CKMTransaction,
                                    withPhoneNumber phoneNumber: GlobalPhoneNumber,
                                    dependencies deps: PayloadPersistenceDependencies) {
    guard tx.phoneNumber == nil, let inputs = ManagedPhoneNumberInputs(phoneNumber: phoneNumber) else {
      return
    }

    let phoneNumberHash = deps.hasher.hash(phoneNumber: phoneNumber,
                                           salt: deps.salt,
                                           parsedNumber: nil)
    tx.phoneNumber = CKMPhoneNumber.findOrCreate(withInputs: inputs,
                                                 phoneNumberHash: phoneNumberHash,
                                                 in: deps.context)

    let counterpartyInputs = deps.contactCacheManager.managedContactComponents(forGlobalPhoneNumber: phoneNumber)?.counterpartyInputs
    if let name = counterpartyInputs?.name {
      tx.phoneNumber?.counterparty = CKMCounterparty.findOrCreate(with: name, in: deps.context)
    }
  }

  /// Returns true if memo parameter was non-empty
  private func configureTransaction(_ tx: CKMTransaction, withMemoIfAppropriate memo: String) -> Bool {
    guard memo.isNotEmpty else { return false }
    if tx.memo == nil { tx.memo = memo }
    return true
  }

  private func payloadsAsV1(from payloads: [Data]) -> [SharedPayloadV1]? {
    let v1Payloads = payloads.compactMap { try? SharedPayloadV1(data: $0) }
    guard v1Payloads.isNotEmpty else { return nil }
    return v1Payloads
  }

  private func payloadsAsV2(from payloads: [Data]) -> [SharedPayloadV2]? {
    let v2Payloads = payloads.compactMap { try? SharedPayloadV2(data: $0) }
    guard v2Payloads.isNotEmpty else { return nil }
    return v2Payloads
  }
}
