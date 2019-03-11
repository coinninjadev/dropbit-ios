//
//  AppCoordinator+TutorialViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: TutorialViewControllerDelegate {
  func tutorialViewControllerDidFinish(_ viewController: UIViewController) {
    viewController.dismiss(animated: true, completion: nil)
  }
}
