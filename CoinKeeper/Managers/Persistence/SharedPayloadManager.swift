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
    ofType walletTxType: WalletTransactionType,
    hasher: HashingManager,
    contactCacheManager: ContactCacheManagerType,
    in context: NSManagedObjectContext)
}

struct PayloadCounterparties {
  let phoneNumber: CKMPhoneNumber?
  let twitterContact: CKMTwitterContact?
}

struct PayloadPersistenceDependencies {
  let hasher: HashingManager
  let salt: Data
  let contactCacheManager: ContactCacheManagerType
  let context: NSManagedObjectContext
}

class SharedPayloadManager: SharedPayloadManagerType {

  func persistReceivedSharedPayloads(
    _ payloads: [Data],
    ofType walletTxType: WalletTransactionType,
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
      self.persistReceivedSharedPayloads(v1Payloads, ofType: walletTxType, with: dependencies)
    }

    if let v2Payloads = self.payloadsAsV2(from: payloads) {
      self.persistReceivedSharedPayloads(v2Payloads, ofType: walletTxType, with: dependencies)
    }
  }

  // MARK: private

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

  private func persistReceivedSharedPayloads(_ payloads: [PersistablePayload],
                                             ofType walletTxType: WalletTransactionType,
                                             with deps: PayloadPersistenceDependencies) {
    for payload in payloads {
      guard let targetObject = payloadConfigurableObject(withId: payload.txid,
                                                         walletTxType: walletTxType,
                                                         in: deps.context) else { continue }
      if targetObject.sharedPayload == nil {
        targetObject.sharedPayload = CKMTransactionSharedPayload(payload: payload, insertInto: deps.context)
      }

      let canSetMemo = (targetObject.memo ?? "").isEmpty // || targetObject.memo == "Generated request"
      if canSetMemo && payload.includesSharedMemo { targetObject.memo = payload.memo }

      let counterparties = payload.payloadCounterparties(with: deps)
      if targetObject.phoneNumber == nil { targetObject.phoneNumber = counterparties?.phoneNumber }
      if targetObject.twitterContact == nil { targetObject.twitterContact = counterparties?.twitterContact }
    }
  }

  private func payloadConfigurableObject(withId id: String,
                                         walletTxType: WalletTransactionType,
                                         in context: NSManagedObjectContext) -> SharedPayloadConfigurable? {
    switch walletTxType {
    case .onChain:
      return CKMTransaction.find(byTxid: id, in: context)
    case .lightning:
      return CKMLNLedgerEntry.find(withId: id, wallet: nil, in: context)?.walletEntry
    }
  }

}

///Shared interface for any object that can have a shared payload
protocol SharedPayloadConfigurable: AnyObject {
  var memo: String? { get set }
  var phoneNumber: CKMPhoneNumber? { get set }
  var twitterContact: CKMTwitterContact? { get set }
  var sharedPayload: CKMTransactionSharedPayload? { get set }
}

extension CKMTransaction: SharedPayloadConfigurable { }
extension CKMWalletEntry: SharedPayloadConfigurable { }

protocol PersistablePayload: SharedPayloadCodable {
  var memo: String { get }
  var txid: String { get }
  var amount: Int { get }
  var currency: String { get }

  func encoded() throws -> Data
  func payloadCounterparties(with deps: PayloadPersistenceDependencies) -> PayloadCounterparties?
}

extension PersistablePayload {

  var includesSharedMemo: Bool {
    return memo.isNotEmpty
  }

  func phoneNumberPayloadCounterparties(forGlobalNumber phoneNumber: GlobalPhoneNumber,
                                        with deps: PayloadPersistenceDependencies) -> PayloadCounterparties? {
    guard let inputs = ManagedPhoneNumberInputs(phoneNumber: phoneNumber) else { return nil }
    let phoneNumberHash = deps.hasher.hash(phoneNumber: phoneNumber, salt: deps.salt, parsedNumber: nil)

    let managedPhoneNumber = CKMPhoneNumber.findOrCreate(withInputs: inputs,
                                                         phoneNumberHash: phoneNumberHash,
                                                         in: deps.context)

    let counterpartyInputs = deps.contactCacheManager.managedContactComponents(forGlobalPhoneNumber: phoneNumber)?.counterpartyInputs
    if let name = counterpartyInputs?.name {
      managedPhoneNumber.counterparty = CKMCounterparty.findOrCreate(with: name, in: deps.context)
    }

    return PayloadCounterparties(phoneNumber: managedPhoneNumber, twitterContact: nil)
  }

}
