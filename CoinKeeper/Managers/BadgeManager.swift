//
//  BadgeManager.swift
//  DropBit
//
//  Created by Ben Winters on 10/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import UIKit

typealias BadgeInfo = [BadgeTopicType: BadgeTopicStatus]

protocol BadgeManagerType: CoreDataObserver {
  func add(topic: BadgeTopic)
  func publishBadgeUpdate()
  func setTransactionsDidDisplay()
  func badgeInfo(for userInfo: [AnyHashable: Any]) -> BadgeInfo

  var badgeTopics: Set<BadgeTopic> { get }
  var wordsBackedUp: Bool { get }
}

class BadgeManager: BadgeManagerType {

  private let persistenceManager: PersistenceManagerType
  private var willSaveContextToken: NotificationToken?
  private var didSaveContextToken: NotificationToken?

  private var saveShouldTriggerBadgeUpdate = false

  private(set) var badgeTopics: Set<BadgeTopic> = []

  init(persistenceManager: PersistenceManagerType) {
    self.persistenceManager = persistenceManager
    observeContextSaveNotifications()
  }

  var wordsBackedUp: Bool {
    return persistenceManager.walletWordsBackedUp()
  }

  func add(topic: BadgeTopic) {
    badgeTopics.insert(topic)
  }

  private func badgeTopic(for type: BadgeTopicType) -> BadgeTopic? {
    return badgeTopics.first { $0.badgeTopicType == type }
  }

  func badgeStatus(forTopicType badgeTopicType: BadgeTopicType, in context: NSManagedObjectContext) -> BadgeTopicStatus {
    guard let topic = badgeTopic(for: badgeTopicType) else { return [.inactive] }
    return topic.badgeStatus(from: persistenceManager, in: context)
  }

  func publishBadgeUpdate() {
    CKNotificationCenter.publish(key: .didUpdateBadgeInfo, object: self, userInfo: userInfo(from: badgeTopics))
  }

  func setTransactionsDidDisplay() {
    persistenceManager.set(false, for: .unseenTransactionChangesExist)
    publishBadgeUpdate()
  }

  /// Only call this function from the main thread
  func badgeInfo(for userInfo: [AnyHashable: Any]) -> BadgeInfo {
    // aggregate a dictionary and return it, mutated by the userInfo
    var badgeInfo: BadgeInfo = [:]
    let context = persistenceManager.mainQueueContext()
    badgeTopics.forEach { topic in
      badgeInfo[topic.badgeTopicType] = badgeStatus(forTopicType: topic.badgeTopicType, in: context)
    }
    if let typedUserInfo = userInfo as? BadgeInfo {
      typedUserInfo.forEach { (key: BadgeTopicType, value: BadgeTopicStatus) in
        badgeInfo[key] = value
      }
    }

    return badgeInfo
  }

  private func userInfo(from badgeTopics: Set<BadgeTopic>) -> [AnyHashable: Any] {
    var result: [String: BadgeTopicStatus] = [:]
    badgeTopics.forEach { topic in
      result[topic.notificationKey] = topic.badgeTopicStatus
    }
    return result
  }
}

enum PersistenceChangeType: String, CaseIterable {
  case insert, update, delete
}

extension BadgeManager: CoreDataObserver {

  func setContextNotificationTokens(willSaveToken: NotificationToken, didSaveToken: NotificationToken) {
    self.willSaveContextToken = willSaveToken
    self.didSaveContextToken = didSaveToken
  }

  func handleWillSaveContext(_ context: NSManagedObjectContext) {
    for topic in badgeTopics {
      if topic.changesShouldTriggerBadgeUpdate(persistenceManager: persistenceManager, in: context) {
        self.saveShouldTriggerBadgeUpdate = true
        break
      }
    }
  }

  func handleDidSaveContext(_ context: NSManagedObjectContext) {
    guard saveShouldTriggerBadgeUpdate else { return }
    publishBadgeUpdate()
    saveShouldTriggerBadgeUpdate = false
  }
}
