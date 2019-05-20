//
//  SharedPayloadV2.swift
//  DropBit
//
//  Created by BJ Miller on 5/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit

struct SharedPayloadProfileV2: Codable {
  let type: UserIdentityType
  let identity: String
  let displayName: String?
  let dropbitMe: String?
  let avatar: String?
}

extension SharedPayloadProfileV2 {
  init(globalPhoneNumber: GlobalPhoneNumber) {
    self.type = UserIdentityType.phone
    self.identity = globalPhoneNumber.asE164()
    self.displayName = nil
    self.dropbitMe = nil
    self.avatar = nil
  }

  /// Return GlobalPhoneNumber instance from `identity`. Return nil if `identity` is not a phone number.
  func globalPhoneNumber() -> GlobalPhoneNumber? {
    guard type == .phone else { return nil }
    return GlobalPhoneNumber(e164: identity, kit: PhoneNumberKit())
  }

  init(twitterContact: TwitterContactType) {
    self.type = UserIdentityType.twitter
    self.identity = twitterContact.identityHash + ":" + twitterContact.twitterUser.screenName
    self.displayName = twitterContact.displayName
    self.dropbitMe = nil
    self.avatar = nil
  }

  /// Return TwitterContact instance by splitting `identity`. Return nil if `identity` is not in <snowflake>:<screenname> format.
  func twitterContact() -> TwitterContact? {
    guard let user = twitterUser() else { return nil }
    return TwitterContact(twitterUser: user)
  }

  private func twitterUser() -> TwitterUser? {
    guard type == .twitter else { return nil }
    let split = identity.split(separator: ":")
    let first = split.first.map { String($0) }
    let last = split.last.map { String($0) }
    guard let idStr = first,
      let screenName = last else { return nil }
    return TwitterUser(
      idStr: idStr,
      name: displayName ?? "",
      screenName: screenName,
      description: nil,
      url: nil,
      profileImageUrlHttps: nil,
      profileImageData: nil)
  }
}

struct SharedPayloadV2: SharedPayloadCodable {
  let meta: SharedPayloadMetadata
  let txid: String
  let info: SharedPayloadInfoV1
  let profile: SharedPayloadProfileV2?

  init(txid: String, memo: String?, amountInfo: SharedPayloadAmountInfo, dropBitType: OutgoingTransactionDropBitType) {
    self.meta = SharedPayloadMetadata(version: 1)
    self.txid = txid
    self.info = SharedPayloadInfoV1(memo: memo ?? "", amountInfo: amountInfo)
    switch dropBitType {
    case .phone(let phoneContact): self.profile = SharedPayloadProfileV2(globalPhoneNumber: phoneContact.globalPhoneNumber)
    case .twitter(let twitterContact): self.profile = SharedPayloadProfileV2(twitterContact: twitterContact)
    case .none: self.profile = nil
    }
  }
}

/* Sample V2 Payload

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
     "type": "twitter" -or- "phone",
     "identity": "123456789:aliceandbob" -or- "+13305551212",
     "display_name": "Alice Bob",
     "dropbit_me": "dropbit.me/@aliceandbob",
     "avatar": "aW5zZXJ0IGF2YXRhciBoZXJlCg=="
   }
 }

 */
