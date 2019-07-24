//
//  CKNotificationCenter.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public enum CKNotificationKey: String {

  case didUpdateExchangeRates
  case didUpdateFees
  case didUpdateBalance
  case didSendTransactionSuccessfully
  case didUpdateBadgeInfo
  case didStartSync
  case didFinishSync
  case didUpdateAvatar
  case willShowTransactionHistoryDetails
  case didDismissTransactionHistoryDetails

  fileprivate func value() -> String {
    return "com.coinninja.CoinKeeper." + self.rawValue
  }
}

public struct CKNotificationCenter {

  //convenience wrapper for NSNotificationCenter
  //Note: the 'object' parameter can be used to filter notifications based on the sender, but it isn't required

  private static let notificationCenter = NotificationCenter.default

  // Publish

  public static func publish(notification: Notification) {
    notificationCenter.post(notification)
  }

  public static func publish(key: CKNotificationKey, object: AnyObject? = nil, userInfo: [AnyHashable: Any]? = nil) {
    notificationCenter.post(name: NSNotification.Name(rawValue: key.value()), object: object, userInfo: userInfo)
  }

  // Subscribe

  public static func subscribe(_ observer: AnyObject, key: CKNotificationKey, selector: Selector, object: AnyObject? = nil) {
    return notificationCenter.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: key.value()), object: object)
  }

  public static func subscribe(_ observer: AnyObject, _ notifications: [CKNotificationKey: Selector], object: AnyObject? = nil) {
    for (key, selector) in notifications {
      subscribe(observer, key: key, selector: selector, object: object)
    }
  }

  /// Convenience wrapper for addObserver(forName:object:queue:using:)
  /// that returns our custom NotificationToken.
  public static func subscribe(
    key: CKNotificationKey,
    object obj: Any?,
    queue: OperationQueue?,
    using block: @escaping (Notification) -> Void) -> NotificationToken {

    let token = notificationCenter.addObserver(forName: NSNotification.Name(rawValue: key.value()), object: obj, queue: queue, using: block)
    return NotificationToken(notificationCenter: notificationCenter, token: token)
  }

  // Unsubscribe

  public static func unsubscribe(_ observer: AnyObject, key: CKNotificationKey? = nil, object: AnyObject? = nil) {
    let mappedName = key.map { NSNotification.Name(rawValue: $0.value()) }
    return notificationCenter.removeObserver(observer, name: mappedName, object: nil)
  }

  public static func unsubscribe(_ observer: AnyObject, _ keys: [CKNotificationKey], object: AnyObject? = nil) {
    for key in keys {
      unsubscribe(observer, key: key, object: object)
    }
  }

}
