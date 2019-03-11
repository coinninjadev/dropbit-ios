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
  let countryCode: Int
  let phoneNumber: String
}

public struct RequestAddressBody: Encodable {
  let amount: RequestAddressAmount
  let sender: RequestAddressUser
  let receiver: RequestAddressUser
  let requestId: String

  init(amount: BitcoinUSDPair, receiverNumber: GlobalPhoneNumber, senderNumber: GlobalPhoneNumber, requestId: String) {
    self.amount = RequestAddressAmount(usd: amount.usdAmount.asFractionalUnits(of: .USD),
                                       btc: amount.btcAmount.asFractionalUnits(of: .BTC))
    self.sender = RequestAddressUser(countryCode: senderNumber.countryCode,
                                     phoneNumber: senderNumber.nationalNumber)
    self.receiver = RequestAddressUser(countryCode: receiverNumber.countryCode,
                                       phoneNumber: receiverNumber.nationalNumber)
    self.requestId = requestId
  }
}
