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
    switch viewController.viewModel {
    case is PaymentSuccessFailViewModel:
      viewControllerDidRetryPayment()
    case is RestoreWalletSuccessFailViewModel:
      navigationController.popToViewController(navigationController.viewControllers[1], animated: true)
    default:
      break
    }
  }

  func viewController(_ viewController: SuccessFailViewController, success: Bool, completion: CKCompletion?) {
    switch viewController.viewModel {
    case is PaymentSuccessFailViewModel:
      CKNotificationCenter.publish(key: .didSendTransactionSuccessfully)
      viewController.dismiss(animated: false) { [weak self] in
        self?.navigationController.topViewController()?.dismiss(animated: true, completion: completion)
      }
    case is RestoreWalletSuccessFailViewModel:
      startDeviceVerificationFlow(userIdentityType: .phone, shouldOrphanRoot: true, selectedSetupFlow: .restoreWallet)
    default:
      break
    }
  }
}
