//
//  RequestAddressResponse.swift
//  CoinKeeper
//
//  Created by Mitchell on 6/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct RequestAddressAmount: Codable {
  let usd: Int
  let btc: Int
}

struct RequestAddressUser: Codable {
  let type: String
  let identity: String

  init(phoneNumber: GlobalPhoneNumber) {
    self.type = UserIdentityType.phone.rawValue
    self.identity = phoneNumber.sanitizedGlobalNumber()
  }
}

public struct RequestAddressBody: Encodable {
  let amount: RequestAddressAmount
  let sender: RequestAddressUser
  let receiver: RequestAddressUser
  let requestId: String

  init(amount: BitcoinUSDPair, receiverNumber: GlobalPhoneNumber, senderNumber: GlobalPhoneNumber, requestId: String) {
    self.amount = RequestAddressAmount(usd: amount.usdAmount.asFractionalUnits(of: .USD),
                                       btc: amount.btcAmount.asFractionalUnits(of: .BTC))
    self.sender = RequestAddressUser(phoneNumber: senderNumber)
    self.receiver = RequestAddressUser(phoneNumber: receiverNumber)
    self.requestId = requestId
  }
}
