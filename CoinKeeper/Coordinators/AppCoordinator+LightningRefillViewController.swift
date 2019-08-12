//
//  AppCoordinator+LightningRefillViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension AppCoordinator: LightningRefillViewControllerDelegate {

  func fiveButtonWasTouched() {

  }

  func twentyButtonWasTouched() {

  }

  func hundredButtonWasTouched() {

  }

  func customAmountButtonWasTouched() {

  }

  func dontAskMeAgainButtonWasTouched() {
    persistenceManager.brokers.preferences.dontShowLightningRefill = true
  }

}
