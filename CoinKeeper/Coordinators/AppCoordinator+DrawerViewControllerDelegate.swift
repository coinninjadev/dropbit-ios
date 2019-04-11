//
//  AppCoordinator+DrawerViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: DrawerViewControllerDelegate {

  func backupWordsWasTouched() {
    analyticsManager.track(event: .backupWordsButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    self.showWordRecoveryFlow()
  }

  func phoneButtonWasTouched() {
    analyticsManager.track(event: .phoneButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    let phoneNumberStatusViewController = PhoneNumberStatusViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: phoneNumberStatusViewController)
    navigationController.present(phoneNumberStatusViewController, animated: true, completion: nil)
  }

  func settingsButtonWasTouched() {
    analyticsManager.track(event: .settingsButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    let settingsViewController = SettingsViewController.makeFromStoryboard()
    settingsViewController.mode = .settings
    assignCoordinationDelegate(to: settingsViewController)
    let settingsNavigationController = CNNavigationController(rootViewController: settingsViewController)
    navigationController.present(settingsNavigationController, animated: true, completion: nil)
  }

  func spendButtonWasTouched() {
    analyticsManager.track(event: .spendButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true) { _ in
      self.openURL(URL(string: "https://coinninja.com/news/where-can-i-spend-my-bitcoin")!, completionHandler: nil)
    }
  }

  func supportButtonWasTouched() {
    analyticsManager.track(event: .supportButtonPressed, with: nil)
    drawerController?.toggle(.left, animated: true, completion: nil)
    let settingsViewController = SettingsViewController.makeFromStoryboard()
    settingsViewController.mode = .support
    assignCoordinationDelegate(to: settingsViewController)
    navigationController.present(settingsViewController, animated: true, completion: nil)
  }
}
