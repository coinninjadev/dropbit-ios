//
//  BadgeDisplayable.swift
//  DropBit
//
//  Created by Ben Winters on 10/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

struct BadgeTopicStatus: OptionSet {
  let rawValue: Int

  /// The badge should not be shown for this topic
  static let inactive = BadgeTopicStatus(rawValue: 1 << 0)

  /// Some action is required to dismiss this topic
  static let actionNeeded = BadgeTopicStatus(rawValue: 1 << 1)

  /// The topic contents have not yet been seen by the user
  static let unseen = BadgeTopicStatus(rawValue: 1 << 2)

}

/**
 Conforming classes should call subscribeToBadgeNotifications() then requestBadgeUpdate() after loading.
 This can handle updating mutiple Badgeable subviews.
 */
protocol BadgeDisplayable: AnyObject {
  var badgeNotificationToken: NotificationToken? { get set }

  /// Call updateBadge on each Badgeable view
  func didReceiveBadgeUpdate(badgeInfo: BadgeInfo)
}

extension BadgeDisplayable {

  func subscribeToBadgeNotifications(with badgeManager: BadgeManagerType) {
    badgeNotificationToken = nil

    badgeNotificationToken = CKNotificationCenter.subscribe(
      key: .didUpdateBadgeInfo,
      object: nil,
      queue: nil,
      using: { [weak self] notification in

        guard let localSelf = self else { return }
        guard let userInfo = notification.userInfo else { return }

        DispatchQueue.main.async {
          let badgeInfo = badgeManager.badgeInfo(for: userInfo)
          localSelf.didReceiveBadgeUpdate(badgeInfo: badgeInfo)
        }
    })
  }

}

protocol BadgeUpdateDelegate: AnyObject {
  func viewControllerDidRequestBadgeUpdate(_ viewController: UIViewController)
}
