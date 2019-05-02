//
//  AppCoordinator+ViewControllerDismissable.swift
//  DropBit
//
//  Created by Ben Winters on 2/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol ViewControllerDismissable: AnyObject {

  /// The delegate should dismiss the viewController
  func viewControllerDidSelectClose(_ viewController: UIViewController)

}

extension AppCoordinator: ViewControllerDismissable {

  func viewControllerDidSelectClose(_ viewController: UIViewController) {
    DispatchQueue.main.async {
      viewController.dismiss(animated: true, completion: nil)
    }
  }
}
