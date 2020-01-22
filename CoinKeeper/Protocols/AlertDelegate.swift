//
//  AlertDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 1/22/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol AlertDelegate: AnyObject {
  func viewControllerDidRequestAlert(_ viewController: UIViewController, title: String?, message: String)
  func viewControllerDidRequestAlert(_ viewController: UIViewController, error: DBTErrorType)
  func viewControllerDidRequestAlert(_ viewController: UIViewController, viewModel: AlertControllerViewModel)
}
