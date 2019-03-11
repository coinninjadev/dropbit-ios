//
//  AppCoordinator+MemoEntryViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 11/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: MemoEntryViewControllerDelegate {
  func viewControllerDidDismiss(_ viewController: UIViewController) {
    viewController.dismiss(animated: true, completion: nil)
  }
}
