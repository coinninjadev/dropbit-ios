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

  var currentLockStatus: LockStatus = LockStatus(rawValue: CKUserDefaults().string(for:
  .lightningWalletLockedStatus) ?? LockStatus.locked.rawValue) ?? .locked

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return statusBarStyle
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .lightGrayBackground
    setAccessibilityIdentifiers()
    registerForLockStatusNotification()
    currentLockStatus == .locked ? lock() : unlock()
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
}

enum LockStatus: String {
  case locked
  case unlocked
}

extension BaseViewController {

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
  }

}
