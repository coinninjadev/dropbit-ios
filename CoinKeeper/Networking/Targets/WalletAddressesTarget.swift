//
//  WalletAddressesTarget.swift
//  DropBit
//
//  Created by Ben Winters on 9/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum WalletAddressesTarget: CoinNinjaTargetType {
  typealias ResponseType = WalletAddressResponse

  case create(AddWalletAddressBody)
  case get

  /// Address to delete
  case delete(String)

  static var autogenerateInvoicesAddressValue: String {
    return "generate"
  }
}

extension WalletAddressesTarget {

  var basePath: String {
    return "wallet/addresses"
  }

  var subPath: String? {
    switch self {
    case .delete(let address):
      return address
    case .create, .get:
      return nil
    }
  }

  public var method: Method {
    switch self {
    case .create:   return .post
    case .get:      return .get
    case .delete:   return .delete
    }
  }

  public var task: Task {
    switch self {
    case .create(let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .get, .delete:
      return .requestPlain
    }
  }

}
