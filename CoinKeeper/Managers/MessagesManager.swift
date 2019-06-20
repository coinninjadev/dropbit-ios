//
//  MessagesManager.swift
//  DropBit
//
//  Created by Mitch on 9/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol MessagesManagerType {
  init(alertManager: AlertManagerType, persistenceManager: PersistenceManagerType)
  func setShouldShowGlobalMessaging(_ show: Bool)
  func showNewAndCache(_ messages: [MessageResponse])
}

class MessageManager: MessagesManagerType {

  private var alertManager: AlertManagerType
  private var persistenceManager: PersistenceManagerType

  private var shownMessageIds: [String] {
    return persistenceManager.brokers.activity.shownMessageIds
  }

  private var shouldShowGlobalMessages = true

  required init(alertManager: AlertManagerType, persistenceManager: PersistenceManagerType) {
    self.alertManager = alertManager
    self.persistenceManager = persistenceManager
  }

  func setShouldShowGlobalMessaging(_ show: Bool) {
    shouldShowGlobalMessages = false
  }

  func showNewAndCache(_ messages: [MessageResponse]) {
    guard shouldShowGlobalMessages else { return }

    guard var newMessages = checkForNew(messages), !newMessages.isEmpty else { return }
    var newestPublishedMessageTimeInterval: Double = persistenceManager.brokers.activity.lastPublishedMessageTime ?? 0
    newMessages.sort()

    for message in newMessages {
      self.alertManager.showBannerAlert(for: message, completion: { [weak self] in
        guard let strongSelf = self else { return }
        let newShownMessageIds = [message.id] + strongSelf.shownMessageIds
        strongSelf.persistenceManager.brokers.activity.shownMessageIds = newShownMessageIds
      })

      if message.publishedAt > newestPublishedMessageTimeInterval {
        newestPublishedMessageTimeInterval = message.publishedAt
      }
    }

    persistenceManager.brokers.activity.lastPublishedMessageTime = newestPublishedMessageTimeInterval
  }

  private func checkForNew(_ messages: [MessageResponse]) -> [MessageResponse]? {
    guard !messages.isEmpty else { return nil }
    return messages.filter { !persistenceManager.brokers.activity.shownMessageIds.contains($0.id) }
  }

  //Not currently being used since metadata usage is currently not defined, but should be used once metadata is more defined
  private func filterStale(_ messages: [MessageResponse]) -> [MessageResponse] {
    let lastTimeInterval = persistenceManager.brokers.activity.lastPublishedMessageTime ?? 0
    return messages.filter { ($0.metadata?.displayTtl ?? 0.0) > lastTimeInterval }
  }
}
