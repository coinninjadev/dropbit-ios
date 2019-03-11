//
//  AppCoordinator+ChildCoordinatorDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 7/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

extension AppCoordinator: ChildCoordinatorDelegate {
  func childCoordinatorDidComplete(childCoordinator: ChildCoordinatorType) {
    if let index = childCoordinators.index(where: { $0 === childCoordinator }) {
      // Joy. No remove(object:) in swift
      childCoordinators.remove(at: index)
    }
  }
}
