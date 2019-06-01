//
//  SenderBodyFactory.swift
//  DropBit
//
//  Created by Ben Winters on 5/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct SenderBodyFactory {
  let persistenceManager: PersistenceManagerType

  func preferredSenderBody(forReceiverType receiverIdentityType: UserIdentityType) -> UserIdentityBody? {
    let twitterBody: UserIdentityBody? = senderTwitterBody()
    let phoneBody: UserIdentityBody? = senderPhoneBody()

    switch receiverIdentityType {
    case .phone:    return phoneBody ?? twitterBody
    case .twitter:  return twitterBody ?? phoneBody
    }
  }

  private func senderPhoneBody() -> UserIdentityBody? {
    guard let number = persistenceManager.verifiedPhoneNumber() else { return nil }
    return UserIdentityBody(phoneNumber: number)
  }

  private func senderTwitterBody() -> UserIdentityBody? {
    guard let creds = persistenceManager.keychainManager.oauthCredentials() else { return nil }
    return UserIdentityBody(twitterCredentials: creds)
  }

}
