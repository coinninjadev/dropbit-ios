//
//  OutgoingTransactionDropBitType.swift
//  DropBit
//
//  Created by BJ Miller on 5/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

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

  var userIdentityType: UserIdentityType {
    switch self {
    case .phone:    return .phone
    case .twitter:  return .twitter
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

protocol DropBitReceiverPersistable: AnyObject {
  var phoneNumber: CKMPhoneNumber? { get set }
  var twitterContact: CKMTwitterContact? { get set }
}

extension DropBitReceiverPersistable {
  func configure(withReceiver receiver: OutgoingDropBitReceiver, in context: NSManagedObjectContext) {
    switch receiver {
    case .phone(let phoneContact):
      if let inputs = ManagedPhoneNumberInputs(phoneNumber: phoneContact.globalPhoneNumber) {
        let number = CKMPhoneNumber.findOrCreate(withInputs: inputs, phoneNumberHash: receiver.identityHash, in: context)
        number.configure(withReceiver: receiver, in: context)
        self.phoneNumber = number
      }
    case .twitter(let twitterContact):
      self.twitterContact = CKMTwitterContact.findOrCreate(with: twitterContact, in: context)
    }
  }
}

protocol SenderSharedPayloadPersistable: AnyObject {
  var memo: String? { get set }
  var sharedPayload: CKMTransactionSharedPayload? { get set }
}

extension SenderSharedPayloadPersistable {
  func configureNewSenderSharedPayload(with sharedPayloadDTO: SharedPayloadDTO, in context: NSManagedObjectContext) {

    self.memo = sharedPayloadDTO.memo

    guard self.sharedPayload == nil,
      let amountInfo = sharedPayloadDTO.amountInfo,
      sharedPayloadDTO.shouldShare //don't persist if not shared
      else { return }

    self.sharedPayload = CKMTransactionSharedPayload(sharingDesired: sharedPayloadDTO.sharingDesired,
                                                     fiatAmount: amountInfo.fiatAmount,
                                                     fiatCurrency: amountInfo.fiatCurrencyCode.rawValue,
                                                     receivedPayload: nil,
                                                     insertInto: context)
  }
}

extension CKMWalletEntry: DropBitReceiverPersistable, SenderSharedPayloadPersistable { }
extension CKMTransaction: DropBitReceiverPersistable, SenderSharedPayloadPersistable { }
