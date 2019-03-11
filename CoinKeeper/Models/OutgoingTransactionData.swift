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
  var contactName: String
  var contactPhoneNumber: GlobalPhoneNumber?
  var contactPhoneNumberHash: String
  var destinationAddress: String
  var amount: Int
  var feeAmount: Int
  var sentToSelf: Bool
  var requiredFeeRate: Double? // BIP 70
  var sharedPayloadDTO: SharedPayloadDTO?

  static func emptyInstance() -> OutgoingTransactionData {
    return OutgoingTransactionData(txid: "", contactName: "",
                                   contactPhoneNumber: nil,
                                   contactPhoneNumberHash: "",
                                   destinationAddress: "",
                                   amount: 0, feeAmount: 0, sentToSelf: false,
                                   requiredFeeRate: nil, sharedPayloadDTO: SharedPayloadDTO.emptyInstance())
  }

  func copy(withTxid txid: String) -> OutgoingTransactionData {
    var copy = self
    copy.txid = txid
    return copy
  }

}
