//
//  BaseViewController.swift
//  DropBit
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController, AccessibleViewSettable {

  var lockStatusNotification: NotificationToken?
  var unlockStatusNotification: NotificationToken?
  var unavailableStatusNotification: NotificationToken?

  var currentLockStatus: LockStatus = LockStatus(rawValue: CKUserDefaults().string(for:
  .lightningWalletLockedStatus) ?? LockStatus.locked.rawValue) ?? .locked

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return statusBarStyle
  }

  func refreshLockStatus() {
    switch currentLockStatus {
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
      CKUserDefaults().set(LockStatus.locked.rawValue, for: .lightningWalletLockedStatus)

      if self?.currentLockStatus != .locked {
        self?.currentLockStatus = .locked
        self?.lock()
      }
    })

    unlockStatusNotification = CKNotificationCenter.subscribe(key: .didUnlockLightning, object: nil, queue: .main, using: { [weak self] _ in
      CKUserDefaults().set(LockStatus.unlocked.rawValue, for: .lightningWalletLockedStatus)

      if self?.currentLockStatus != .unlocked {
        self?.currentLockStatus = .unlocked
        self?.unlock()
      }
    })

    unavailableStatusNotification = CKNotificationCenter.subscribe(key: .lightningUnavailable, object: nil, queue: .main, using: { [weak self] _ in
      CKUserDefaults().set(LockStatus.unavailable.rawValue, for: .lightningWalletLockedStatus)

      if self?.currentLockStatus != .unavailable {
        self?.currentLockStatus = .unavailable
        self?.makeUnavailable()
      }
    })
  }

}

enum LockStatus: String {
  case locked
  case unlocked
  case unavailable
}
