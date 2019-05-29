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
      let parser = CKPhoneNumberParser(kit: PhoneNumberKit())
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
}

public struct RequestAddressBody: Encodable {
  let amount: RequestAddressAmount
  let sender: UserIdentityBody
  let receiver: UserIdentityBody
  let requestId: String
  let suppress: Bool

  init(amount: BitcoinUSDPair,
       receiver: UserIdentityBody,
       sender: UserIdentityBody,
       requestId: String,
       suppress: Bool) {
    self.amount = RequestAddressAmount(usd: amount.usdAmount.asFractionalUnits(of: .USD),
                                       btc: amount.btcAmount.asFractionalUnits(of: .BTC))
    self.sender = sender
    self.receiver = receiver
    self.requestId = requestId
    self.suppress = suppress
  }
}
