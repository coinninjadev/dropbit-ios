//
//  BaseViewController.swift
//  DropBit
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController, AccessibleViewSettable {

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

extension BaseViewController {

  enum LockStatus {
    case locked
    case unlocked
  }

  static var lockStatus: LockStatus = .locked

  fileprivate func registerForLockStatusNotification() {
    CKNotificationCenter.subscribe(key: .didLockLightning, object: nil, queue: .main, using: { [weak self] _ in
      BaseViewController.lockStatus = .locked
      self?.lock()
    })

    CKNotificationCenter.subscribe(key: .didUnlockLightning, object: nil, queue: .main, using: { [weak self] _ in
      BaseViewController.lockStatus = .unlocked
      self?.unlock()
    })
  }

}
