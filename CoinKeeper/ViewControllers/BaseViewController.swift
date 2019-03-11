//
//  BaseViewController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol Coordination: class {
  var generalCoordinationDelegate: AnyObject? { get set }
}

class BaseViewController: UIViewController, Coordination, AccessibleViewSettable {
  weak var generalCoordinationDelegate: AnyObject?

  var statusBarStyle: UIStatusBarStyle = .default {
    didSet {
      setNeedsStatusBarAppearanceUpdate()
    }
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return statusBarStyle
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Theme.Color.lightGrayBackground.color
    setAccessibilityIdentifiers()
  }

  /// Subclasses with identifiers should override this method and return the appropriate array
  func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return []
  }

}
