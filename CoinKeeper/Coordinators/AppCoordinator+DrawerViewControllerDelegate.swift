//
//  AppCoordinator+DrawerViewControllerDelegate.swift
//  DropBit
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

  func verifyButtonWasTouched() {
    analyticsManager.track(event: .phoneButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    showVerificationStatusViewController()
  }

  func showVerificationStatusViewController() {
    let verificationStatusViewController = VerificationStatusViewController.newInstance(delegate: self)
    navigationController.present(verificationStatusViewController, animated: true, completion: nil)
  }

  func settingsButtonWasTouched() {
    analyticsManager.track(event: .settingsButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    let settingsViewController = SettingsViewController.newInstance(with: self)
    let settingsNavigationController = CNNavigationController(rootViewController: settingsViewController)
    settingsNavigationController.navigationBar.tintColor = .darkBlueBackground
    navigationController.present(settingsNavigationController, animated: true, completion: nil)
  }

  func spendButtonWasTouched() {
    analyticsManager.track(event: .spendButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    let controller = SpendBitcoinViewController.newInstance(delegate: self)
    navigationController.pushViewController(controller, animated: true)
  }

  func supportButtonWasTouched() {
    analyticsManager.track(event: .supportButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    let viewController = SupportViewController.newInstance(with: self)
    navigationController.present(viewController, animated: true, completion: nil)
  }

  func getBitcoinButtonWasTouched() {
    guard let controller = drawerController else { return }
    controller.toggle(.left, animated: true, completion: nil)
    viewControllerDidTapGetBitcoin(controller)
  }
}
