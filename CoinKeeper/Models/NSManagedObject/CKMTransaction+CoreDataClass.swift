//
//  CKMTransaction+CoreDataClass.swift
//  DropBit
//
//  Created by BJ Miller on 4/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import PhoneNumberKit

@objc(CKMTransaction)
public class CKMTransaction: NSManagedObject {

  public override func awakeFromInsert() {
    super.awakeFromInsert()
    setPrimitiveValue("", forKey: #keyPath(CKMTransaction.txid))
    setPrimitiveValue(false, forKey: #keyPath(CKMTransaction.isSentToSelf))
    setPrimitiveValue(false, forKey: #keyPath(CKMTransaction.broadcastFailed))
  }

  static let confirmationThreshold = 1
  static let fullyConfirmedThreshold = 6

  static let invitationTxidPrefix = "Invitation_"
  static let failedTxidPrefix = "Failed_"

  func configure(
    with txResponse: TransactionResponse,
    in context: NSManagedObjectContext,
    relativeToBlockHeight blockHeight: Int,
    fullSync: Bool
    ) {
    // configure the tx here
    if let tempSentTx = temporarySentTransaction, txResponse.txid == txid {
      context.delete(tempSentTx)
    }
    txid = txResponse.txid
    blockHash = txResponse.blockHash
    confirmations = (txResponse.blockHash ?? "").isEmpty ? 0 : txResponse.blockheight.map { (blockHeight - $0) + 1 } ?? 0
    date = txResponse.receivedTime ?? txResponse.date
    sortDate = txResponse.sortDate
    network = "btc://main"

    // vins
    if self.vins.isEmpty || fullSync {
      let vinArray = txResponse.vinResponses.map { (vinResponse: TransactionVinResponse) -> CKMVin in
        let vin = CKMVin.findOrCreate(with: vinResponse, in: context)
        vin.transaction = self
        return vin
      }
      self.vins = Set(vinArray)
    }

    // vouts
    let voutArray = txResponse.voutResponses.compactMap { (voutResponse: TransactionVoutResponse) -> CKMVout? in
      let vout = CKMVout.findOrCreate(with: voutResponse, in: context, fullSync: fullSync)
      vout?.transaction = self
      return vout
    }
    self.vouts = Set(voutArray)

    isIncoming = calculateIsIncoming(in: context)

    let atss = CKMAddressTransactionSummary.find(byTxid: txResponse.txid, in: context)
    addressTransactionSummaries = atss.asSet()
    atss.forEach { $0.transaction = self } // just being extra careful to ensure bi-directional integrity

    if !isIncoming {
      self.isSentToSelf = txResponse.isSentToSelf
    }
  }

  func calculateIsSentToSelf(in context: NSManagedObjectContext) -> Bool {
    // any changes to this method should also change TransactionDataWorker's isSentToSelf calculation

    guard invitation == nil else { return false }

    if let temp = temporarySentTransaction {
      return temp.isSentToSelf
    } else {
      // regular transaction
      let allVoutAddresses = vouts.flatMap { $0.addressIDs }.asSet()
      let ownedVoutAddresses = allVoutAddresses
        .compactMap { CKMAddress.find(withAddress: $0, in: context) }
        .map { $0.addressId }
        .asSet()

      return allVoutAddresses.subtracting(ownedVoutAddresses).isEmpty
    }
  }

  func calculateIsIncoming(in context: NSManagedObjectContext) -> Bool {
    if let invitation = self.invitation {
      return invitation.side == .receiver
    }
    let incoming = vins.filter { $0.belongsToWallet }.isEmpty
    return incoming
  }

  /// Configures a newly created Transaction object with an instance of OutgoingTransactionData DTO.
  ///
  /// - Parameters:
  ///   - outgoingTransactionData: The DTO (data transfer object) which accumulates data about the
  ///     outgoing transaction through the send flow. The included SharedPayloadDTO is ignored by this function.
  ///   - phoneNumber: Optional PhoneNumber. If nil, will attempt to find-or-create by phone number string in
  ///     outgoingTransactionData.
  ///   - context: The NSManagedObjectContext within which this operation will be executed.
  ///     The caller of this method should use `perform` or `performAndWait` and call this method inside that block.
  func configure(with outgoingTransactionData: OutgoingTransactionData, phoneNumber: CKMPhoneNumber? = nil, in context: NSManagedObjectContext) {
    // self.txid should remain as an empty string so that the outgoingTransactionData.txid UUID
    // doesn't trigger a 4xx error when sending txids to the server

    self.sortDate = Date()
    self.date = self.sortDate
    self.isSentToSelf = outgoingTransactionData.sentToSelf
    self.isIncoming = false
    self.memo = outgoingTransactionData.sharedPayloadDTO?.memo

    if outgoingTransactionData.txid.isNotEmpty {
      self.txid = outgoingTransactionData.txid
    }

    if self.txid.starts(with: CKMTransaction.invitationTxidPrefix) {
      self.txid = outgoingTransactionData.txid
    }

    counterpartyAddress = CKMCounterpartyAddress.findOrCreate(withAddress: outgoingTransactionData.destinationAddress, in: context)

    let tempTx = temporarySentTransaction ?? CKMTemporarySentTransaction(insertInto: context)
    tempTx.amount = outgoingTransactionData.amount
    tempTx.feeAmount = outgoingTransactionData.feeAmount
    tempTx.isSentToSelf = outgoingTransactionData.sentToSelf
    tempTx.txid = outgoingTransactionData.txid
    tempTx.transaction = self

    guard let receiver = outgoingTransactionData.receiver else { return }
    if let number = phoneNumber {
      number.configure(withReceiver: receiver, in: context)
      self.phoneNumber = number
    } else {
      self.configure(withReceiver: receiver, in: context)
    }
  }

  func configure(with lightningResponse: LNTransactionResponse, in context: NSManagedObjectContext) {
    self.sortDate = Date()
    self.date = self.sortDate
    self.isSentToSelf = false
    self.isIncoming = true
    self.txid = lightningResponse.result.id

    let tempTx = temporarySentTransaction ?? CKMTemporarySentTransaction(insertInto: context)
    tempTx.amount = -lightningResponse.result.value - lightningResponse.result.networkFee
    tempTx.feeAmount = lightningResponse.result.networkFee
    tempTx.isSentToSelf = false
    tempTx.txid = lightningResponse.result.id
    tempTx.transaction = self
  }

  /// Returns early if this transaction already has a CKMTransactionSharedPayload attached
  func markAsFailed() {
    broadcastFailed = true

    // Replace failed txid with a prefix + timestamp + UUID to free up the unique constraint in case an identical transaction is retried by the user
    // txid may or may not be an actual txid depending on sender/receiver or actual/invitation
    self.txid = CKMTransaction.failedTxidPrefix + String(Date().timeIntervalSince1970) + UUID().uuidString

    // Free up the temporary transactions
    temporarySentTransaction?.reservedVouts.forEach { vout in
      vout.isSpent = false
      vout.temporarySentTransaction = nil
    }
  }

  static let transactionHistorySortDescriptors: [NSSortDescriptor] = [
    NSSortDescriptor(key: #keyPath(CKMTransaction.sortDate), ascending: false)
  ]

  static func findLatest(in context: NSManagedObjectContext) -> CKMTransaction? {
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.fetchLimit = 1
    fetchRequest.sortDescriptors = transactionHistorySortDescriptors

    do {
      return try context.fetch(fetchRequest).first
    } catch {
      log.error(error, message: "Could not execute fetch request for latest transaction")
      return nil
    }
  }

  var isInvite: Bool {
    return invitation != nil
  }

  var isConfirmed: Bool {
    return confirmations >= CKMTransaction.confirmationThreshold
  }

  var isLightningUpgrade: Bool {
    guard vouts.count == 1, let vout = vouts.first else { return false }
    let addresses = vouts.compactMap { $0.address }
    guard let firstAddress = addresses.first else { return false }
    guard let path = firstAddress.derivativePath else { return false }
    let isLightningPath = (path.change == 1) && (path.index == 0)
    let relatedTransactions = vouts.compactMap { $0.transaction }.sorted { (tx1, tx2) -> Bool in
      (tx1.sortDate ?? Date()) < (tx2.sortDate ?? Date())
    }
    let isFirstUTXO = vout.transaction == relatedTransactions.first
    return isLightningPath && isFirstUTXO
  }

}

extension CKMTransaction {
  static func == (lhs: CKMTransaction, rhs: CKMTransaction) -> Bool {
    return lhs.txid == rhs.txid
  }
}

extension CKMTransaction: InvitationParent { }
