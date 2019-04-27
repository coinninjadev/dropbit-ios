//
//  AppCoordinator+InvitationWorkerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 7/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit

protocol InvitationWorkerDelegate: AnyObject {
  func fetchAndHandleSentWalletAddressRequests() -> Promise<[PendingInvitationData]>
}

extension AppCoordinator: InvitationWorkerDelegate {

  func fetchAndHandleSentWalletAddressRequests() -> Promise<[PendingInvitationData]> {
    return self.networkManager.getSatisfiedSentWalletAddressRequests()
      .then { self.matchingPendingInvitations(from: $0) }
  }

  // MARK: private helpers
  private func matchingPendingInvitations(from responses: [WalletAddressRequestResponse]) -> Promise<[PendingInvitationData]> {

    let foundIDs = responses.compactMap { $0.id }
    guard foundIDs.isNotEmpty else { return Promise.value([]) }

    let localPendingInvitations = responses.compactMap { (response: WalletAddressRequestResponse) -> PendingInvitationData? in
      if var pendingInvitationData = self.persistenceManager.pendingInvitation(with: response.id) {
        pendingInvitationData.address = response.address
        pendingInvitationData.addressPubKey = response.addressPubkey
        return pendingInvitationData
      } else {
        return PendingInvitationData(walletAddressRequestResponse: response, kit: self.phoneNumberKit)
      }
    }

    return Promise.value(localPendingInvitations)
  }

}
