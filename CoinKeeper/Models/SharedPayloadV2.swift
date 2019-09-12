//
//  SharedPayloadV2.swift
//  DropBit
//
//  Created by BJ Miller on 5/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct SharedPayloadProfileV2: Codable {
  let type: UserIdentityType
  let identity: String
  var displayName: String?
  var dropbitMe: String?
  var avatar: String?
}

extension SharedPayloadProfileV2 {
  init(globalPhoneNumber: GlobalPhoneNumber) {
    self.type = UserIdentityType.phone
    self.identity = globalPhoneNumber.asE164()
    self.displayName = nil
    self.dropbitMe = nil
    self.avatar = nil
  }

  func copy(byUpdatingIdentity newIdentity: String) -> SharedPayloadProfileV2 {
    return SharedPayloadProfileV2(type: self.type,
                                  identity: newIdentity,
                                  displayName: self.displayName,
                                  dropbitMe: self.dropbitMe,
                                  avatar: self.avatar)
  }

  /// Return GlobalPhoneNumber instance from `identity`. Return nil if `identity` is not a phone number.
  func globalPhoneNumber() -> GlobalPhoneNumber? {
    guard type == .phone else { return nil }
    return GlobalPhoneNumber(e164: identity)
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
      verified: false,
      profileImageUrlHttps: nil,
      profileImageData: nil)
  }
}

struct SharedPayloadV2: SharedPayloadCodable {
  let meta: SharedPayloadMetadata
  let txid: String
  let info: SharedPayloadInfoV1
  var profile: SharedPayloadProfileV2?

  init(txid: String, memo: String?, amountInfo: SharedPayloadAmountInfo, senderIdentity: UserIdentityBody) {
    self.meta = SharedPayloadMetadata(version: 2)
    self.txid = txid
    self.info = SharedPayloadInfoV1(memo: memo ?? "", amountInfo: amountInfo)
    self.profile = SharedPayloadProfileV2(type: senderIdentity.identityType,
                                          identity: senderIdentity.identity,
                                          displayName: senderIdentity.handle,
                                          dropbitMe: nil,
                                          avatar: nil)
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

extension SharedPayloadV2: PersistablePayload {
  var memo: String {
    return self.info.memo
  }

  var amount: Int {
    return self.info.amount
  }

  var currency: String {
    return self.info.currency
  }

  func payloadCounterparties(with deps: PayloadPersistenceDependencies) -> PayloadCounterparties? {
    guard let profile = self.profile else { return nil }
    switch profile.type {
    case .phone:
      guard let phoneNumber = profile.globalPhoneNumber() else { return nil }
      return phoneNumberPayloadCounterparties(forGlobalNumber: phoneNumber, with: deps)

    case .twitter:
      guard let twitterContact = profile.twitterContact() else { return nil }
      let twitter = CKMTwitterContact.findOrCreate(with: twitterContact, in: deps.context)
      return PayloadCounterparties(phoneNumber: nil, twitterContact: twitter)
    }
  }

}
