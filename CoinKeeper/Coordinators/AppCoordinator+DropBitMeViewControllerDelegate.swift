//
//  AppCoordinator+DropBitMeViewControllerDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 4/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: DropBitMeViewControllerDelegate {

  func viewControllerDidEnableDropBitMeURL(_ viewController: UIViewController, shouldEnable: Bool) {
    let bgContext = self.persistenceManager.createBackgroundContext()
    self.alertManager.showActivityHUD(withStatus: nil)
    self.networkManager.updateDropBitMe(enabled: shouldEnable)
      .get(in: bgContext) { response in
        
      }
      .done(in: bgContext) { response in

      }
      .catch { error in
        self.alertManager.showError(message: "Failed to change DropBit enabled. \(error.localizedDescription)", forDuration: 3.0)
    }
      .finally {
        self.alertManager.hideActivityHUD(withDelay: nil, completion: nil)
    }
  }

  func viewControllerDidTapDisableDropBitMeURL(_ viewController: UIViewController) {
    print(#function)
  }

  func viewControllerDidTapLearnMore(_ viewController: UIViewController) {
    print(#function)
  }

  func viewControllerDidTapShareOnTwitter(_ viewController: UIViewController) {
    print(#function)
  }

}
