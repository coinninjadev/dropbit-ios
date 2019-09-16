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

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return statusBarStyle
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .lightGrayBackground
    setAccessibilityIdentifiers()
    registerForLockStatusNotification()
    BaseViewController.lockStatus == .locked ? lock() : unlock()
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

  static var lockStatus: LockStatus = LockStatus(rawValue: CKUserDefaults().string(for:
    .lightningWalletLockedStatus) ?? LockStatus.locked.rawValue) ?? .locked

  fileprivate func registerForLockStatusNotification() {
    lockStatusNotification = CKNotificationCenter.subscribe(key: .didLockLightning, object: nil, queue: .main, using: { [weak self] _ in
      BaseViewController.lockStatus = .locked
      self?.lock()
    })

    unlockStatusNotification = CKNotificationCenter.subscribe(key: .didUnlockLightning, object: nil, queue: .main, using: { [weak self] _ in
      BaseViewController.lockStatus = .unlocked
      self?.unlock()
    })
  }

}
