//
//  ContactType.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/31/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum ContactKind {
  case generic
  case registeredUser
  case invite
}

protocol ContactType {

  var kind: ContactKind { get set }
  var displayName: String? { get }
  var displayNumber: String { get }
  var phoneNumberHash: String { get }
  var globalPhoneNumber: GlobalPhoneNumber { get }

}

struct ValidatedContact: ContactType {

  var kind: ContactKind
  let displayName: String?
  let displayNumber: String
  let phoneNumberHash: String
  let globalPhoneNumber: GlobalPhoneNumber

  init?(cachedNumber: CCMPhoneNumber) {
    guard let metadata = cachedNumber.cachedValidatedMetadata,
      let displayName = cachedNumber.cachedContact?.displayName
      else { return nil }

    switch cachedNumber.verificationStatus {
    case .verified:     self.kind = .registeredUser
    case .notVerified:  self.kind = .invite
    }

    self.displayName = displayName
    self.displayNumber = cachedNumber.displayNumber
    self.phoneNumberHash = metadata.hashedGlobalNumber
    self.globalPhoneNumber = GlobalPhoneNumber(countryCode: metadata.countryCode, nationalNumber: metadata.nationalNumber)
  }

}

struct GenericContact: ContactType {

  var kind: ContactKind
  var displayName: String?
  var displayNumber: String
  var phoneNumberHash: String
  var globalPhoneNumber: GlobalPhoneNumber

  init(phoneNumber: GlobalPhoneNumber, hash: String, formatted: String) {
    self.kind = .generic
    self.displayName = nil
    self.displayNumber = formatted
    self.phoneNumberHash = hash
    self.globalPhoneNumber = phoneNumber
  }

}
