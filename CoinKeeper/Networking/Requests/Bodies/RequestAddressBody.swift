//
//  RequestAddressResponse.swift
//  CoinKeeper
//
//  Created by Mitchell on 6/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit

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

extension RequestAddressUser {
  func globalNumber() -> GlobalPhoneNumber? {
    let parser = CKPhoneNumberParser(kit: PhoneNumberKit())
    do {
      let e164 = "+" + identity
      return try parser.parse(e164)
    } catch {
      return nil
    }
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
