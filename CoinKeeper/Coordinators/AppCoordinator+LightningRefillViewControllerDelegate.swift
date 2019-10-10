//
//  AppCoordinator+LightningRefillViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension AppCoordinator: LightningRefillViewControllerDelegate {

  func dontAskMeAgainButtonWasTouched() {
    persistenceManager.brokers.preferences.dontShowLightningRefill = true
  }
}
