//
//  SharedPayloadV1.swift
//  DropBit
//
//  Created by Ben Winters on 1/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct SharedPayloadMetadata: Codable {
  let version: Int
}

struct SharedPayloadInfoV1: Codable {
  let memo: String
  let amount: Int
  let currency: String

  init(memo: String, amountInfo: SharedPayloadAmountInfo) {
    self.memo = memo
    self.amount = amountInfo.fiatAmount
    self.currency = amountInfo.fiatCurrencyCode.rawValue
  }
}

struct SharedPayloadProfileV1: Codable {
  let displayName: String?
  let countryCode: Int
  let phoneNumber: String
  let dropbitMe: String?
  let avatar: String?

  init(globalNumber: GlobalPhoneNumber) {
    self.displayName = nil
    self.countryCode = globalNumber.countryCode
    self.phoneNumber = globalNumber.nationalNumber
    self.dropbitMe = nil
    self.avatar = nil
  }

  func globalPhoneNumber() -> GlobalPhoneNumber {
    return GlobalPhoneNumber(countryCode: countryCode, nationalNumber: phoneNumber)
  }
}

struct SharedPayloadV1: SharedPayloadCodable {
  let meta: SharedPayloadMetadata
  let txid: String
  let info: SharedPayloadInfoV1
  let profile: SharedPayloadProfileV1

  init(txid: String, memo: String?, amountInfo: SharedPayloadAmountInfo, senderPhoneNumber: GlobalPhoneNumber) {
    self.meta = SharedPayloadMetadata(version: 1)
    self.txid = txid
    self.info = SharedPayloadInfoV1(memo: memo ?? "", amountInfo: amountInfo)
    self.profile = SharedPayloadProfileV1(globalNumber: senderPhoneNumber)
  }
}

struct SharedPayloadVersionIdentifier: SharedPayloadCodable {
  var meta: SharedPayloadMetadata
  var version: Int { return meta.version }
}

/* Sample V1 Payload
   {
     "meta": {
       "version": 1
     },
     "txid": "....",
     "info": {
       "memo": "Here's your 5 dollars 💸",
       "amount": 500,
       "currency": "USD"
     },
     "profile": {
       "display_name": "",
       "country_code": 1,
       "phone_number": "3305551122",
       "dropbit_me": "",
       "avatar": "aW5zZXJ0IGF2YXRhciBoZXJlCg=="
     }
   }
 */

extension SharedPayloadV1: PayloadPersistable {

  var amount: Int {
    return self.info.amount
  }

  var currency: String {
    return self.info.currency
  }

  var memo: String {
    return self.info.memo
  }

  func payloadCounterparties(with deps: PayloadPersistenceDependencies) -> PayloadCounterparties? {
    return phoneNumberPayloadCounterparties(forGlobalNumber: self.profile.globalPhoneNumber(), with: deps)
  }

}
