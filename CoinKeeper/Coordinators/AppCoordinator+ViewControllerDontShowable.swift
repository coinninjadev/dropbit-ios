//
//  AppCoordinator+ViewControllerDontShowable.swift
//  DropBit
//
//  Created by Ben Winters on 4/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: ViewControllerDontShowable {

  func viewControllerRequestedDontShowAgain(_ viewController: UIViewController) {
    switch viewController {
    case is ShareTransactionViewController:
      self.persistenceManager.brokers.preferences.dontShowShareTransaction = true
      self.analyticsManager.track(event: .sharePromptNever, with: nil)
      viewController.dismiss(animated: true, completion: nil)
    default:
      break
    }
  }

}
