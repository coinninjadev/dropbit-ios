//
//  AppCoordinator+ConnectionManagerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 7/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import os.log

extension AppCoordinator: ConnectionManagerDelegate {
  func connectionManager(_ manager: ConnectionManagerType, didChangeStatusTo status: ConnectionManagerStatus) {
    navigationController.topViewController().map { manager.updateOverlay(from: $0, forStatus: status, completion: nil) }
  }

  func connectionManagerDidRequestRetry(_ manager: ConnectionManagerType) {
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "retry_checkin")
    networkManager.walletCheckIn()
      .done { _ in manager.setAPIUnreachable(false) }
      .catch { error in
        os_log("failed to reach Coin Ninja check-in route", log: logger, type: .error)
        self.connectionManager(manager, didChangeStatusTo: .none)
    }
  }
}
