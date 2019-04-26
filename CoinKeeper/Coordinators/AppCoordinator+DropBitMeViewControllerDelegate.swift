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
    self.networkManager.updateUserPublicURL(enabled: shouldEnable)
      .get(in: bgContext) { response in
        self.persistenceManager.persistUserPublicURLInfo(response, in: bgContext)
      }
      .done(in: bgContext) { _ in
        try bgContext.save()
        if let urlInfo = self.persistenceManager.getUserPublicURLInfo(in: bgContext) {
          DispatchQueue.main.async {
            if let dropbitMeVC = viewController as? DropBitMeViewController,
              let url = CoinNinjaUrlFactory.buildUrl(for: .dropBitMe(publicURLId: urlInfo.id)) {
              dropbitMeVC.configure(with: .verified(url, urlInfo.enabled))
            }
          }

        }
      }
      .catch { error in
        self.alertManager.showError(message: "Failed to change DropBit.me URL status. Error: \(error.localizedDescription)", forDuration: 3.0)
    }
      .finally {
        self.alertManager.hideActivityHUD(withDelay: nil, completion: nil)
    }
  }

  func viewControllerDidTapLearnMore(_ viewController: UIViewController) {
    print(#function)
  }

  func viewControllerDidTapShareOnTwitter(_ viewController: UIViewController) {
    print(#function)
  }

}
