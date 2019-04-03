//
//  AppCoordinator+CalculatorViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: CalculatorViewControllerDelegate {
  func viewControllerDidTapSendPaymentWithInvalidAmount(_ viewController: UIViewController, error: ValidatorTypeError) {
    let alert = alertManager.defaultAlert(withTitle: "Invalid Amount", description: error.displayMessage)
    navigationController.topViewController()?.present(alert, animated: true, completion: nil)
  }
}
