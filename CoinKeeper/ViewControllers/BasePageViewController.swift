//
//  BasePageViewController.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class BasePageViewController: UIPageViewController, Coordination, AccessibleViewSettable {
  weak var generalCoordinationDelegate: AnyObject?

  var statusBarStyle: UIStatusBarStyle = .default {
    didSet {
      setNeedsStatusBarAppearanceUpdate()
    }
  }

  func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return []
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return statusBarStyle
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setAccessibilityIdentifiers()
  }

}
