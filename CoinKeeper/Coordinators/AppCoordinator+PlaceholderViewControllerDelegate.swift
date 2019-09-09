//
//  AppCoordinator+PlaceholderViewControllerDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 5/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: PlaceholderViewControllerDelegate {
  func viewControllerRequestPayTapped(_ viewController: UIViewController) {
    let viewController = RequestPayViewController.newInstance(delegate: self, viewModel: nil, alertManager: self.alertManager)
    viewController.modalPresentationStyle = .custom
    viewController.modalTransitionStyle = UIModalTransitionStyle.coverVertical

    navigationController.present(viewController, animated: true, completion: nil)
  }
}
