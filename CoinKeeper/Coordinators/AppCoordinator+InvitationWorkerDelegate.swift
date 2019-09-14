//
//  AppCoordinator+InvitationWorkerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 7/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit

protocol InvitationWorkerDelegate: AnyObject {
  func fetchSatisfiedSentWalletAddressRequests() -> Promise<[WalletAddressRequestResponse]>
  func didBroadcastTransaction()
}

extension AppCoordinator: InvitationWorkerDelegate {

  func fetchSatisfiedSentWalletAddressRequests() -> Promise<[WalletAddressRequestResponse]> {
    return self.networkManager.getSatisfiedSentWalletAddressRequests()
  }

  func didBroadcastTransaction() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
      self?.serialQueueManager.enqueueOptionalIncrementalSync()
    }
  }

}
