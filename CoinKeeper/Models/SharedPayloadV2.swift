//
//  SharedPayloadV2.swift
//  DropBit
//
//  Created by BJ Miller on 5/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum SharedPayloadType: String, Codable {
  case phone
  case twitter
  case coinninja
  case unknown
}

struct SharedPayloadProfileV2: Codable {
  let type: SharedPayloadType
  let identity: String
  var displayName: String?
  var dropbitMe: String?
  var avatar: String?

  init(type: SharedPayloadType,
       identity: String,
       displayName: String?,
       dropbitMe: String?,
       avatar: String?) {
    self.type = type
    var identityStr: String = identity
    if type == .twitter, let handle = displayName {
      identityStr += ":\(handle)"
    }
    self.identity = identityStr
    self.displayName = displayName
    self.dropbitMe = dropbitMe
    self.avatar = avatar
  }
}

extension SharedPayloadProfileV2 {
  init(globalPhoneNumber: GlobalPhoneNumber) {
    self.type = SharedPayloadType.phone
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
    self.type = SharedPayloadType.twitter
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
  var txid: String
  let info: SharedPayloadInfoV1
  var profile: SharedPayloadProfileV2?

  init(txid: String, memo: String?, amountInfo: SharedPayloadAmountInfo, senderIdentity: UserIdentityBody) {
    self.meta = SharedPayloadMetadata(version: 2)
    self.txid = txid
    self.info = SharedPayloadInfoV1(memo: memo ?? "", amountInfo: amountInfo)
    let sharedPayloadType = SharedPayloadType(rawValue: senderIdentity.type) ?? .unknown
    self.profile = SharedPayloadProfileV2(type: sharedPayloadType,
                                          identity: senderIdentity.identity,
                                          displayName: senderIdentity.handle,
                                          dropbitMe: nil,
                                          avatar: nil)
  }

  init(preauthInvitationDTO invitationDTO: OutgoingInvitationDTO, senderIdentity: UserIdentityBody) throws {
    guard let payloadDTO = invitationDTO.sharedPayloadDTO else {
      throw CKPersistenceError.missingValue(key: "sharedPayloadDTO")
    }

    guard let amountInfo = payloadDTO.amountInfo else {
      throw CKPersistenceError.missingValue(key: "amountInfo")
    }

    self.init(txid: "",
              memo: payloadDTO.sharingObservantMemo,
              amountInfo: amountInfo,
              senderIdentity: senderIdentity)
  }

  func copy(withId txid: String) -> SharedPayloadV2 {
    var copy = self
    copy.txid = txid
    return copy
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
      return PayloadCounterparties(phoneNumber: nil, twitterContact: twitter, counterparty: nil)
    case .coinninja:
      var data: Data?
      if let avatar = profile.avatar, let scheme = DataURIScheme(string: avatar) { data = Data(base64Encoded: scheme.payload) }
      let counterparty = CKMCounterparty(name: "Referral Bonus", insertInto: deps.context, profileImageData: data)
      counterparty.kind = CKMCounterparty.Kind.referral.rawValue
      return PayloadCounterparties(phoneNumber: nil, twitterContact: nil, counterparty: counterparty)
    default:
      let counterparty = CKMCounterparty(name: "Unknown", insertInto: deps.context)
      return PayloadCounterparties(phoneNumber: nil, twitterContact: nil, counterparty: counterparty)
    }
  }

}
