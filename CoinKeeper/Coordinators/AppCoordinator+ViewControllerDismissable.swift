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
  func viewControllerDidSelectClose(_ viewController: UIViewController, completion: CKCompletion?)

}

extension AppCoordinator: ViewControllerDismissable {

  func viewControllerDidSelectClose(_ viewController: UIViewController) {
    viewControllerDidSelectClose(viewController, completion: nil)
  }

  func viewControllerDidSelectClose(_ viewController: UIViewController, completion: CKCompletion? = nil) {
    DispatchQueue.main.async {
      viewController.dismiss(animated: true, completion: completion)
    }
  }
}
