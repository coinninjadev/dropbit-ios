//
//  RequestAddressResponse.swift
//  DropBit
//
//  Created by Mitchell on 6/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct WalletAddressRequestAmount: Codable {
  let usd: Int
  let btc: Int
}

public struct UserIdentityBody: Codable {
  let type: String
  let identity: String
  var handle: String?

  init(type: String, identity: String, handle: String?) {
    self.type = type
    self.identity = identity
    self.handle = handle
  }

  init(phoneNumber: GlobalPhoneNumber) {
    self.type = UserIdentityType.phone.rawValue
    self.identity = phoneNumber.sanitizedGlobalNumber()
  }

  init(twitterCredentials: TwitterOAuthStorage) {
    self.type = UserIdentityType.twitter.rawValue
    self.identity = twitterCredentials.twitterUserId
    self.handle = twitterCredentials.formattedScreenName
  }

  init(twitterUser: TwitterUser) {
    self.type = UserIdentityType.twitter.rawValue
    self.identity = twitterUser.idStr
    self.handle = twitterUser.formattedScreenName
  }

  init(participant: MetadataParticipant) {
    self.type = UserIdentityType.twitter.rawValue
    self.identity = participant.identity
    self.handle = participant.handle
  }

  static func sharedPayloadBody(twitterCredentials: TwitterOAuthStorage) -> UserIdentityBody {
    let joinedIdentity = twitterCredentials.twitterUserId + ":" + twitterCredentials.twitterScreenName
    return UserIdentityBody(type: UserIdentityType.twitter.rawValue,
                            identity: joinedIdentity,
                            handle: twitterCredentials.formattedScreenName)
  }
}

extension UserIdentityBody {
  func globalNumber() -> GlobalPhoneNumber? {
    switch identityType {
    case .phone:
      let parser = CKPhoneNumberParser()
      do {
        let e164 = "+" + identity
        return try parser.parse(e164)
      } catch {
        return nil
      }
    case .twitter: return nil
    }
  }

  var identityHash: String {
    switch identityType {
    case .phone:
      return globalNumber()?.hashed() ?? ""
    case .twitter:
      return identity
    }
  }

  var identityType: UserIdentityType {
    return UserIdentityType(rawValue: type) ?? .phone
  }

  func twitterUser() -> TwitterUser {
    return TwitterUser(idStr: identity,
                       name: "",
                       screenName: handle ?? "",
                       description: nil,
                       url: nil,
                       verified: false,
                       profileImageUrlHttps: nil,
                       profileImageData: nil)
  }
}

public struct WalletAddressRequestBody: Encodable {
  let amount: WalletAddressRequestAmount
  let sender: UserIdentityBody
  let receiver: UserIdentityBody
  let requestId: String
  let suppress: Bool
  let addressType: String
  var preauthId: String?

  init(amount: BitcoinUSDPair,
       receiver: UserIdentityBody,
       sender: UserIdentityBody,
       requestId: String,
       addressType: WalletAddressType) {
    let usdCents = amount.usdAmount.asFractionalUnits(of: .USD)
    let roundedUpCents = max(usdCents, 1) //server requires a non-zero integer for small amounts, e.g. 1 sat
    self.amount = WalletAddressRequestAmount(usd: roundedUpCents,
                                             btc: amount.btcAmount.asFractionalUnits(of: .BTC))
    self.sender = sender
    self.receiver = receiver
    self.requestId = requestId
    self.suppress = receiver.identityType == .twitter
    self.addressType = addressType.rawValue
  }
}
