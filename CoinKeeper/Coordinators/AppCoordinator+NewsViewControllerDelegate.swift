//
//  AppCoordinator+NewsViewControllerDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 6/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

extension AppCoordinator: NewsViewControllerDelegate {
  func viewControllerDidRequestNewsData() -> Promise<NewsData> {
    return Promise { _ in } //TODO
  }

}
