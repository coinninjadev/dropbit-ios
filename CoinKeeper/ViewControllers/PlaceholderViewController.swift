//
//  PlaceholderViewController.swift
//  DropBit
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
  private(set) weak var delegate: PlaceholderViewControllerDelegate?

  @IBAction func clearPinTapped(_ sender: UIButton) {
    delegate.clearPin()
  }

  @IBAction func requestPayTapped(_ sender: UIButton) {
    delegate.viewControllerRequestPayTapped(self)
  }
}
