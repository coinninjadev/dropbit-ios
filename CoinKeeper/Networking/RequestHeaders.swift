//
//  RequestHeaders.swift
//  CoinKeeper
//
//  Created by Ben Winters on 6/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/**
 Putting all these headers in one place since they will be refactored into a Moya plugin
 to automatically add the walletId and userId headers to all requests.
 */

public struct DefaultRequestHeaders: CKRequestHeadersProvider {
  var walletId: String
  var userId: String

  public var dictionary: Headers {
    return CNHeaderParameter.dictionary(
      withKeyValues: [
        .authWalletId: walletId,
        .authUserId: userId
      ]
    )
  }
}

public typealias CNHeaderParameterDict = [CNHeaderParameter: String]
public typealias Headers = [String: String]

public enum CNHeaderParameter: String {
  case authSignature = "CN-Auth-Signature"
  case authTimestamp = "CN-Auth-Timestamp"
  case authUserId = "CN-Auth-User-ID"
  case authWalletId = "CN-Auth-Wallet-ID"
  case deviceId = "CN-Auth-Device-UUID"
  case devicePlatform = "CN-Device-Platform"
  case appVersion = "CN-App-Version"
  case buildEnvironment = "CN-Build-Environment"
  case pubKeyString = "CN-Auth-PubKeyString"

  var fieldName: String {
    return self.rawValue
  }

  static func dictionary(withKeyValues paramDict: CNHeaderParameterDict) -> Headers {
    // Create dictionary with the rawValue of each enum case in paramDict
    return Dictionary(uniqueKeysWithValues: paramDict.map { key, value in (key.fieldName, value) })
  }
}
