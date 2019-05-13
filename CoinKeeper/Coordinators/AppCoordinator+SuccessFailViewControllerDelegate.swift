//
//  AppCoordinator+SuccessFailViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: SuccessFailViewControllerDelegate {
  func viewControllerDidRetry(_ viewController: SuccessFailViewController) {
    switch viewController.viewModel.flow {
    case .payment:
      viewControllerDidRetryPayment()
    case .restoreWallet:
      navigationController.popToViewController(navigationController.viewControllers[1], animated: true)
    }
  }

  func viewController(_ viewController: SuccessFailViewController, success: Bool, completion: (() -> Void)?) {
    switch viewController.viewModel.flow {
    case .payment:
      CKNotificationCenter.publish(key: .didSendTransactionSuccessfully)
      viewController.dismiss(animated: false) { [weak self] in
        self?.navigationController.topViewController()?.dismiss(animated: true, completion: completion)
      }
    case .restoreWallet:
      startDeviceVerificationFlow(shouldOrphanRoot: true, isInitialSetupFlow: true)
    }
  }

}
