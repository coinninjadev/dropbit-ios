//
//  WalletTransactionType.swift
//  DropBit
//
//  Created by Mitchell Malleo on 1/20/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public enum WalletAddressType: String {
  case btc, lightning
}

enum WalletTransactionType: String {
  case onChain
  case lightning

  var addressType: WalletAddressType {
    switch self {
    case .onChain:    return .btc
    case .lightning:  return .lightning
    }
  }

  init(addressType: WalletAddressType) {
    switch addressType {
    case .btc:        self = .onChain
    case .lightning:  self = .lightning
    }
  }

}
