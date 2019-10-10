//
//  NetworkManager+TransactionNotificationRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 1/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

protocol TransactionNotificationRequestable: AnyObject {
  func addTransactionNotification(body: CreateTransactionNotificationBody) -> Promise<Void>
  func fetchTransactionNotifications(forId id: String) -> Promise<[TransactionNotificationResponse]>
}

extension NetworkManager: TransactionNotificationRequestable {

  func addTransactionNotification(body: CreateTransactionNotificationBody) -> Promise<Void> {
    return cnProvider.requestVoid(TransactionNotificationTarget.create(body))
  }

  func fetchTransactionNotifications(forId id: String) -> Promise<[TransactionNotificationResponse]> {
    return cnProvider.requestList(TransactionNotificationTarget.get(id))
  }

}
