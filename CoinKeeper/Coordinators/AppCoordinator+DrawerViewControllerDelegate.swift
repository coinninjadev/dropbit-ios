//
//  AppCoordinator+DrawerViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: BadgeUpdateDelegate {
  func viewControllerDidRequestBadgeUpdate(_ viewController: UIViewController) {
    badgeManager.publishBadgeUpdate()
  }
}

extension AppCoordinator: DrawerViewControllerDelegate {

  func backupWordsWasTouched() {
    analyticsManager.track(event: .backupWordsButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    self.showWordRecoveryFlow()
  }

  func phoneButtonWasTouched() {
    analyticsManager.track(event: .phoneButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    let phoneNumberStatusViewController = VerificationStatusViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: phoneNumberStatusViewController)
    navigationController.present(phoneNumberStatusViewController, animated: true, completion: nil)
  }

  func settingsButtonWasTouched() {
    analyticsManager.track(event: .settingsButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    let settingsViewController = SettingsViewController.newInstance(with: self)
    let settingsNavigationController = CNNavigationController(rootViewController: settingsViewController)
    navigationController.present(settingsNavigationController, animated: true, completion: nil)
  }

  func spendButtonWasTouched() {
    analyticsManager.track(event: .spendButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    let controller = SpendBitcoinViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: controller)
    navigationController.pushViewController(controller, animated: true)
  }

  func supportButtonWasTouched() {
    analyticsManager.track(event: .supportButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    let viewController = SupportViewController.newInstance(with: self)
    navigationController.present(viewController, animated: true, completion: nil)
  }

  func getBitcoinButtonWasTouched() {
    analyticsManager.track(event: .getBitcoinButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    let controller = GetBitcoinViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: controller)
    navigationController.pushViewController(controller, animated: true)
  }
}
