//
//  MockNavigationController.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import UIKit

class MockNavigationController: CNNavigationController {
  var pushedViewController: UIViewController?

  var innerViewControllers: [UIViewController] = []
  override var viewControllers: [UIViewController] {
    get {
      return innerViewControllers
    }
    set {
      innerViewControllers = newValue
      super.viewControllers = newValue
    }
  }

  init() {
    super.init(rootViewController: StartViewController.makeFromStoryboard())
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  override func pushViewController(_ viewController: UIViewController, animated: Bool) {
    self.pushedViewController = viewController
    super.pushViewController(viewController, animated: animated)
  }
}
