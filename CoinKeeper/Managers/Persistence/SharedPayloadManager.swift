//
//  SharedPayloadManager.swift
//  DropBit
//
//  Created by BJ Miller on 5/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit
import CoreData
import os.log

protocol SharedPayloadManagerType: AnyObject {
  func persistReceivedSharedPayloads(
    _ payloads: [Data],
    hasher: HashingManager,
    kit: PhoneNumberKit,
    contactCacheManager: ContactCacheManagerType,
    in context: NSManagedObjectContext)
}

class SharedPayloadManager: SharedPayloadManagerType {

  func persistReceivedSharedPayloads(
    _ payloads: [Data],
    hasher: HashingManager,
    kit: PhoneNumberKit,
    contactCacheManager: ContactCacheManagerType,
    in context: NSManagedObjectContext) {
    let salt: Data
    do {
      salt = try hasher.salt()
    } catch {
      os_log("Failed to get salt for hashing shared payload phone number: %@", log: logger, type: .error, error.localizedDescription)
      return
    }

    if let v1Payloads = self.payloadsAsV1(from: payloads) {
      self.persistReceivedV1SharedPayloads(payloads: v1Payloads,
                                           hasher: hasher,
                                           kit: kit,
                                           salt: salt,
                                           contactCacheManager: contactCacheManager,
                                           in: context)
    }

    if let v2Payloads = self.payloadsAsV2(from: payloads) {
      self.persistReceivedV2SharedPayloads(payloads: v2Payloads,
                                           hasher: hasher,
                                           kit: kit,
                                           salt: salt,
                                           contactCacheManager: contactCacheManager,
                                           in: context)
    }
  }

  // MARK: private
  private let logger = OSLog(subsystem: "com.coinninja.coinkeeper.database", category: "shared_payloads")

  private func persistReceivedV1SharedPayloads(
    payloads: [SharedPayloadV1],
    hasher: HashingManager,
    kit: PhoneNumberKit,
    salt: Data,
    contactCacheManager: ContactCacheManagerType,
    in context: NSManagedObjectContext) {

    for payload in payloads {
      guard let tx = CKMTransaction.find(byTxid: payload.txid, in: context) else { continue }

      if tx.memo == nil {
        tx.memo = payload.info.memo
      }

      let phoneNumber = payload.profile.globalPhoneNumber()
      let phoneNumberHash = hasher.hash(phoneNumber: phoneNumber, salt: salt, parsedNumber: nil, kit: kit)

      if tx.phoneNumber == nil, let inputs = ManagedPhoneNumberInputs(phoneNumber: phoneNumber) {
        tx.phoneNumber = CKMPhoneNumber.findOrCreate(withInputs: inputs,
                                                     phoneNumberHash: phoneNumberHash,
                                                     in: context)

        let counterpartyInputs = contactCacheManager.managedContactComponents(forGlobalPhoneNumber: phoneNumber)?.counterpartyInputs
        if let name = counterpartyInputs?.name {
          tx.phoneNumber?.counterparty = CKMCounterparty.findOrCreate(with: name, in: context)
        }
      }

      let payloadAsData = try? payload.encoded()
      let ckmSharedPayload = CKMTransactionSharedPayload(sharingDesired: true,
                                                         fiatAmount: payload.info.amount,
                                                         fiatCurrency: payload.info.currency,
                                                         receivedPayload: payloadAsData,
                                                         insertInto: context)
      tx.sharedPayload = ckmSharedPayload
    }
  }

  private func persistReceivedV2SharedPayloads(
    payloads: [SharedPayloadV2],
    hasher: HashingManager,
    kit: PhoneNumberKit,
    salt: Data,
    contactCacheManager: ContactCacheManagerType,
    in context: NSManagedObjectContext) {

    for payload in payloads {
      guard let tx = CKMTransaction.find(byTxid: payload.txid, in: context) else { continue }

      if tx.memo == nil {
        tx.memo = payload.info.memo
      }

      guard let profile = payload.profile else { continue }
      switch profile.type {
      case .phone:
        guard let phoneNumber = profile.globalPhoneNumber() else { continue }
        let phoneNumberHash = hasher.hash(phoneNumber: phoneNumber, salt: salt, parsedNumber: nil, kit: kit)
        if tx.phoneNumber == nil, let inputs = ManagedPhoneNumberInputs(phoneNumber: phoneNumber) {
          tx.phoneNumber = CKMPhoneNumber.findOrCreate(withInputs: inputs,
                                                       phoneNumberHash: phoneNumberHash,
                                                       in: context)

          let counterpartyInputs = contactCacheManager.managedContactComponents(forGlobalPhoneNumber: phoneNumber)?.counterpartyInputs
          if let name = counterpartyInputs?.name {
            tx.phoneNumber?.counterparty = CKMCounterparty.findOrCreate(with: name, in: context)
          }
        }
      case .twitter:
        guard let twitterContact = profile.twitterContact() else { continue }
        if tx.twitterContact == nil {
          tx.twitterContact = CKMTwitterContact.findOrCreate(with: twitterContact, in: context)
        }
      }

      let payloadAsData = try? payload.encoded()
      let ckmSharedPayload = CKMTransactionSharedPayload(sharingDesired: true,
                                                         fiatAmount: payload.info.amount,
                                                         fiatCurrency: payload.info.currency,
                                                         receivedPayload: payloadAsData,
                                                         insertInto: context)
      tx.sharedPayload = ckmSharedPayload
    }
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
