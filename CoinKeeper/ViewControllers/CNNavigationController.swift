//
//  CNNavigationController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class CNNavigationController: UINavigationController {
  override init(rootViewController: UIViewController) {
    super.init(rootViewController: rootViewController)
    initialize()
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  convenience init() {
    self.init(rootViewController: UIViewController())
  }

  private func initialize() {
    navigationBar.shadowImage = UIImage()
    navigationBar.isTranslucent = true
    navigationBar.setBackgroundImage(UIImage(), for: .default)
    navigationBar.tintColor = .lightBlueTint
    navigationBar.titleTextAttributes = [.font: UIFont.regular(14)]
  }

  override func pushViewController(_ viewController: UIViewController, animated: Bool) {
    super.pushViewController(viewController, animated: animated)
    navigationBar.items?.forEach { item in item.title = "" }
  }
}
