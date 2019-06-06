//
//  OutgoingTransactionData.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct OutgoingTransactionData {
  var txid: String
  var displayName: String
  var displayIdentity: String
  var identityHash: String
  var dropBitType: OutgoingTransactionDropBitType
  var destinationAddress: String
  var amount: Int
  var feeAmount: Int
  var sentToSelf: Bool
  var requiredFeeRate: Double? // BIP 70
  var sharedPayloadDTO: SharedPayloadDTO?

  /// identity property is structured according to SharedPayload requirements
  var sharedPayloadSenderIdentity: UserIdentityBody?

  static func emptyInstance() -> OutgoingTransactionData {
    return OutgoingTransactionData(
      txid: "",
      dropBitType: .none,
      destinationAddress: "",
      amount: 0,
      feeAmount: 0,
      sentToSelf: false,
      requiredFeeRate: 0,
      sharedPayloadDTO: SharedPayloadDTO.emptyInstance())
  }

  init(
    txid: String,
    dropBitType: OutgoingTransactionDropBitType,
    destinationAddress: String,
    amount: Int,
    feeAmount: Int,
    sentToSelf: Bool,
    requiredFeeRate: Double?,
    sharedPayloadDTO: SharedPayloadDTO?,
    sharedPayloadSenderIdentity: UserIdentityBody? = nil) {
    self.txid = txid
    self.dropBitType = dropBitType
    self.displayName = dropBitType.displayName ?? "" //contact.displayName ?? ""
    self.displayIdentity = dropBitType.displayIdentity //contact.displayIdentity
    self.identityHash = dropBitType.identityHash //contact.identityHash

    self.destinationAddress = destinationAddress
    self.amount = amount
    self.feeAmount = feeAmount
    self.sentToSelf = sentToSelf
    self.requiredFeeRate = requiredFeeRate
    self.sharedPayloadDTO = sharedPayloadDTO
    self.sharedPayloadSenderIdentity = sharedPayloadSenderIdentity
  }

  func copy(withTxid txid: String) -> OutgoingTransactionData {
    var copy = self
    copy.txid = txid
    return copy
  }
}

extension OutgoingTransactionData {
  var phoneNumberHash: String? {
    return identityHash
  }
}
