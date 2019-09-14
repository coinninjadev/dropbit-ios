//
//  MockNetworkManager+TransactionNotificationRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 1/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import PromiseKit

extension MockNetworkManager: TransactionNotificationRequestable {

  func addTransactionNotification(body: CreateTransactionNotificationBody) -> Promise<Void> {
    return Promise.value(())
  }

  func fetchTransactionNotifications(forId id: String) -> Promise<[TransactionNotificationResponse]> {
    return Promise.value([])
  }

}
