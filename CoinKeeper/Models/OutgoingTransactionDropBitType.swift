//
//  OutgoingTransactionDropBitType.swift
//  DropBit
//
//  Created by BJ Miller on 5/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum OutgoingDropBitReceiver {
  case phone(PhoneContactType)
  case twitter(TwitterContactType)

  init?(contact: ContactType) {
    if let phoneContact = contact as? PhoneContactType {
      self = .phone(phoneContact)
    } else if let twitterContact = contact as? TwitterContactType {
      self = .twitter(twitterContact)
    } else {
      return nil
    }
  }
}

extension OutgoingDropBitReceiver {
  var displayName: String? {
    switch self {
    case .phone(let contact): return contact.displayName
    case .twitter(let contact): return contact.displayName
    }
  }

  var displayIdentity: String {
    switch self {
    case .phone(let contact): return contact.displayIdentity
    case .twitter(let contact): return contact.displayIdentity
    }
  }

  var identityHash: String {
    switch self {
    case .phone(let contact): return contact.identityHash
    case .twitter(let contact): return contact.identityHash
    }
  }
}
