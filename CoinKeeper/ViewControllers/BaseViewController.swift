//
//  BaseViewController.swift
//  DropBit
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController, AccessibleViewSettable {

  static var lockStatus: LockStatus = LockStatus(rawValue: CKUserDefaults().string(for:
    .lightningWalletLockedStatus) ?? LockStatus.locked.rawValue) ?? .locked

  var lockStatusNotification: NotificationToken?
  var unlockStatusNotification: NotificationToken?
  var unavailableStatusNotification: NotificationToken?

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return statusBarStyle
  }

  func refreshLockStatus() {
    switch BaseViewController.lockStatus {
    case .locked: lock()
    case .unlocked: unlock()
    case .unavailable: makeUnavailable()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .lightGrayBackground
    setAccessibilityIdentifiers()
    registerForLockStatusNotification()

    refreshLockStatus()
  }

  /// Subclasses with identifiers should override this method and return the appropriate array
  func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return []
  }

  var statusBarStyle: UIStatusBarStyle = .default {
    didSet {
      setNeedsStatusBarAppearanceUpdate()
    }
  }

  func unlock() {}
  func lock() {}
  func makeUnavailable() {}

  fileprivate func registerForLockStatusNotification() {
    lockStatusNotification = CKNotificationCenter.subscribe(key: .didLockLightning, object: nil, queue: .main, using: { [weak self] _ in
      BaseViewController.lockStatus = .locked
      self?.lock()
    })

    unlockStatusNotification = CKNotificationCenter.subscribe(key: .didUnlockLightning, object: nil, queue: .main, using: { [weak self] _ in
      BaseViewController.lockStatus = .unlocked
      self?.unlock()
    })

    unavailableStatusNotification = CKNotificationCenter.subscribe(key: .lightningUnavailable, object: nil, queue: .main, using: { [weak self] _ in
      BaseViewController.lockStatus = .unavailable
      self?.makeUnavailable()
    })
  }

}

enum LockStatus: String {
  case locked
  case unlocked
  case unavailable
}
