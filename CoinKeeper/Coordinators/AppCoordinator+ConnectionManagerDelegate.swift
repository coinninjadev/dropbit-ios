//
//  AppCoordinator+ConnectionManagerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 7/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

extension AppCoordinator: ConnectionManagerDelegate {
  func connectionManager(_ manager: ConnectionManagerType, didChangeStatusTo status: ConnectionManagerStatus) {
    navigationController.topViewController().map { manager.updateOverlay(from: $0, forStatus: status, completion: nil) }
  }

  func connectionManagerDidRequestRetry(_ manager: ConnectionManagerType) {
    networkManager.walletCheckIn()
      .done { _ in manager.setAPIUnreachable(false) }
      .catch { error in
        log.error(error, message: "failed to reach Coin Ninja check-in route")
        self.connectionManager(manager, didChangeStatusTo: .none)
    }
  }
}
