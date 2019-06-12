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
  func fetchAndHandleSentWalletAddressRequests() -> Promise<[WalletAddressRequestResponse]>
}

extension AppCoordinator: InvitationWorkerDelegate {

  func fetchAndHandleSentWalletAddressRequests() -> Promise<[WalletAddressRequestResponse]> {
    return self.networkManager.getSatisfiedSentWalletAddressRequests()
  }
}
