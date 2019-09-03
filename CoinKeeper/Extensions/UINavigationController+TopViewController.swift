//
//  UINavigationController+TopViewController.swift
//  DropBit
//
//  Created by Mitchell on 5/1/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UINavigationController {
  //swiftlint:disable force_cast
  func topViewController(base: UIViewController? =
    (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController) -> UIViewController? {
    if let nav = base as? UINavigationController {
      return topViewController(base: nav.visibleViewController)
    }
    if let tab = base as? UITabBarController {
      if let selected = tab.selectedViewController {
        return topViewController(base: selected)
      }
    }
    if let presented = base?.presentedViewController {
      return topViewController(base: presented)
    }
    return base
  }

  func orphanDisplayingViewController() {
    guard let lastViewController = self.viewControllers.last else { return }
    self.viewControllers = [lastViewController]
  }
}
