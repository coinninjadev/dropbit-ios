//
//  SenderIdentityFactory.swift
//  DropBit
//
//  Created by Ben Winters on 5/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct SenderIdentityFactory {
  let persistenceManager: PersistenceManagerType

  /// Returns a UserIdentityBody appropriate for including in a wallet address request
  func preferredAddressRequestSenderIdentity(forReceiverType receiverIdentityType: UserIdentityType) -> UserIdentityBody? {
    let twitterBody: UserIdentityBody? = senderTwitterBody()
    let phoneBody: UserIdentityBody? = senderPhoneBody()

    switch receiverIdentityType {
    case .phone:    return phoneBody ?? twitterBody
    case .twitter:  return twitterBody ?? phoneBody
    }
  }

  /// Returns a UserIdentityBody appropriate for including in a wallet address request, the twitterBody includes a colon-separated identity
  func preferredSharedPayloadSenderIdentity(forReceiver receiver: OutgoingDropBitReceiver?) -> UserIdentityBody? {
    guard let receiver = receiver else { return nil }
    let phoneBody: UserIdentityBody? = senderPhoneBody()

    var twitterBody: UserIdentityBody?
    if let creds = persistenceManager.keychainManager.oauthCredentials() {
      twitterBody = UserIdentityBody.sharedPayloadBody(twitterCredentials: creds)
    }

    switch receiver {
    case .phone:    return phoneBody ?? twitterBody
    case .twitter:  return twitterBody ?? phoneBody
    }
  }

  private func senderPhoneBody() -> UserIdentityBody? {
    guard let number = persistenceManager.brokers.user.verifiedPhoneNumber() else { return nil }
    return UserIdentityBody(phoneNumber: number)
  }

  private func senderTwitterBody() -> UserIdentityBody? {
    guard let creds = persistenceManager.keychainManager.oauthCredentials() else { return nil }
    return UserIdentityBody(twitterCredentials: creds)
  }

}
