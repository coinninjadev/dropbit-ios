//
//  OutgoingTransactionData.swift
//  DropBit
//
//  Created by BJ Miller on 6/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct OutgoingTransactionData {
  var txid: String
  var destinationAddress: String
  var amount: Int
  var feeAmount: Int
  var sentToSelf: Bool
  var requiredFeeRate: Double? // BIP 70
  var sharedPayloadDTO: SharedPayloadDTO?

  /// identity property is structured according to SharedPayload requirements
  var sender: UserIdentityBody?
  var receiver: OutgoingDropBitReceiver?

  static func emptyInstance() -> OutgoingTransactionData {
    return OutgoingTransactionData(
      txid: "",
      destinationAddress: "",
      amount: 0,
      feeAmount: 0,
      sentToSelf: false,
      requiredFeeRate: 0,
      sharedPayloadDTO: SharedPayloadDTO.emptyInstance(),
      sender: nil,
      receiver: nil)
  }

  init(
    txid: String,
    destinationAddress: String,
    amount: Int,
    feeAmount: Int,
    sentToSelf: Bool,
    requiredFeeRate: Double?,
    sharedPayloadDTO: SharedPayloadDTO?,
    sender: UserIdentityBody?,
    receiver: OutgoingDropBitReceiver?) {
    self.txid = txid
    self.destinationAddress = destinationAddress
    self.amount = amount
    self.feeAmount = feeAmount
    self.sentToSelf = sentToSelf
    self.requiredFeeRate = requiredFeeRate
    self.sharedPayloadDTO = sharedPayloadDTO
    self.sender = sender
    self.receiver = receiver
  }

  func copy(withTxid txid: String) -> OutgoingTransactionData {
    var copy = self
    copy.txid = txid
    return copy
  }
}
