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
  var contact: ContactType?
  var destinationAddress: String
  var amount: Int
  var feeAmount: Int
  var sentToSelf: Bool
  var requiredFeeRate: Double? // BIP 70
  var sharedPayloadDTO: SharedPayloadDTO?

  static func emptyInstance() -> OutgoingTransactionData {
    return OutgoingTransactionData(
      txid: "",
      contact: nil,
      destinationAddress: "",
      amount: 0,
      feeAmount: 0,
      sentToSelf: false,
      requiredFeeRate: 0,
      sharedPayloadDTO: SharedPayloadDTO.emptyInstance())
  }

  func copy(withTxid txid: String) -> OutgoingTransactionData {
    var copy = self
    copy.txid = txid
    return copy
  }
}

extension OutgoingTransactionData {
  var displayName: String {
    return contact?.displayName ?? ""
  }

  var displayIdentity: String {
    return contact?.displayIdentity ?? ""
  }

  var phoneNumberHash: String? {
    return (contact as? PhoneContactType)?.phoneNumberHash
  }
}
