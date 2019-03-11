//
//  PlaceholderViewController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol PlaceholderViewControllerDelegate: AnyObject {
  func clearPin()
  func viewControllerRequestPayTapped(_ viewController: UIViewController)
}

final class PlaceholderViewController: BaseViewController, StoryboardInitializable {
  var coordinationDelegate: PlaceholderViewControllerDelegate? {
    return generalCoordinationDelegate as? PlaceholderViewControllerDelegate
  }

  @IBAction func clearPinTapped(_ sender: UIButton) {
    coordinationDelegate?.clearPin()
  }

  @IBAction func requestPayTapped(_ sender: UIButton) {
    coordinationDelegate?.viewControllerRequestPayTapped(self)
  }
}
