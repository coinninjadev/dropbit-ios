//
//  SyncSubscribeable.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol SyncSubscribeable: class {
  var startSyncNotificationToken: NotificationToken? { get set }
  var finishSyncNotificationToken: NotificationToken? { get set }

  func handleStartSync()
  func handleFinishSync()
}

extension SyncSubscribeable {

  func subscribeToSyncNotifications() {
    startSyncNotificationToken = CKNotificationCenter.subscribe(key: .didStartSync, object: nil, queue: nil) { [weak self] (_) in
      self?.handleStartSync()
    }

    finishSyncNotificationToken = CKNotificationCenter.subscribe(key: .didFinishSync, object: nil, queue: nil) { [weak self] (_) in
      self?.handleFinishSync()
    }
  }
}
