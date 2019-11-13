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
  func fetchTransactionNotifications(forIds ids: [String]) -> Promise<[TransactionNotificationResponse]>
}

extension NetworkManager: TransactionNotificationRequestable {

  func addTransactionNotification(body: CreateTransactionNotificationBody) -> Promise<Void> {
    return cnProvider.requestVoid(TransactionNotificationTarget.create(body))
  }

  func fetchTransactionNotifications(forIds ids: [String]) -> Promise<[TransactionNotificationResponse]> {
    guard ids.isNotEmpty else { return .value([]) }
    let query = TransactionNotificationsElasticQuery(ids: ids)
    let body = ElasticRequest(query: query)
    return cnProvider.requestList(TransactionNotificationTarget.query(body))
  }

}
