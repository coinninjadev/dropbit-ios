//
//  OutgoingTransactionDropBitType.swift
//  DropBit
//
//  Created by BJ Miller on 5/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum OutgoingTransactionDropBitType {
  case phone(PhoneContactType)
  case twitter(TwitterContactType)
  case none // standard btc transaction, not a DropBit
}

extension OutgoingTransactionDropBitType {
  var displayName: String? {
    switch self {
    case .phone(let contact): return contact.displayName
    case .twitter(let contact): return contact.displayName
    case .none: return nil
    }
  }

  var displayIdentity: String {
    switch self {
    case .phone(let contact): return contact.displayIdentity
    case .twitter(let contact): return contact.displayIdentity
    case .none: return ""
    }
  }

  var identityHash: String {
    switch self {
    case .phone(let contact): return contact.identityHash
    case .twitter(let contact): return contact.identityHash
    case .none: return ""
    }
  }
}
