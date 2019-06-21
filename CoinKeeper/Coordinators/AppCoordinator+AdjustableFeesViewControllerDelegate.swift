//
//  AppCoordinator+AdjustableFeesViewControllerDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 6/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: AdjustableFeesViewControllerDelegate {

  var adjustableFeesIsEnabled: Bool {
    get { return persistenceManager.brokers.preferences.adjustableFeesIsEnabled }
    set { persistenceManager.brokers.preferences.adjustableFeesIsEnabled = newValue }
  }

  var preferredTransactionFeeMode: TransactionFeeMode {
    get { return persistenceManager.brokers.preferences.preferredTransactionFeeMode }
    set { persistenceManager.brokers.preferences.preferredTransactionFeeMode = newValue }
  }

}
