//
//  AppCoordinator+ViewControllerURLDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: ViewControllerURLDelegate {

  func viewController(_ viewController: UIViewController, didRequestOpenURL url: URL) {
    openURL(url, completionHandler: nil)
  }

}
