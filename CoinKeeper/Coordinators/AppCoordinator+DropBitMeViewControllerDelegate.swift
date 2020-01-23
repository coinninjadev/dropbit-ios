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
    self.networkManager.updateUserPublicURL(isPrivate: !shouldEnable) // reverse boolean for isEnabled (view) vs. isPrivate (server)
      .get(in: bgContext) { response in
        self.persistenceManager.brokers.user.persistUserPublicURLInfo(from: response, in: bgContext)

        let isPrivate = response.private ?? false
        let event: AnalyticsManagerEventType = isPrivate ? .dropBitMeDisabled : .dropBitMeReenabled
        self.analyticsManager.track(event: event, with: nil)
        self.analyticsManager.track(property: MixpanelProperty(key: .isDropBitMeEnabled, value: !isPrivate))
      }
      .done(in: bgContext) { _ in
        try bgContext.saveRecursively()
        if let urlInfo = self.persistenceManager.brokers.user.getUserPublicURLInfo(in: bgContext) {
          let user = CKMUser.find(in: bgContext)
          let avatarData = user?.avatar
          let holidayType = user?.holidayType ?? .bitcoin
          DispatchQueue.main.async {
            if let dropbitMeVC = viewController as? DropBitMeViewController,
              let handle = urlInfo.primaryIdentity?.handle,
              let url = CoinNinjaUrlFactory.buildUrl(for: .dropBitMe(handle: handle)) {
              var state: DropBitMeConfig.DropBitMeState = .notVerified
              if urlInfo.isEnabled {
                state = .verified(url, firstTime: false)
              } else {
                state = .disabled
              }
              let config = DropBitMeConfig(state: state, userAvatarData: avatarData, holidayType: holidayType)
              dropbitMeVC.configure(with: config)
            }
          }
        }
      }
      .catch { error in
        let dbtError = DBTError.cast(error)
        self.alertManager.showErrorHUD(message: "Failed to change DropBit.me URL status. Error: \(dbtError.displayMessage)", forDuration: 3.0)
      }
      .finally {
        self.alertManager.hideActivityHUD(withDelay: nil, completion: nil)
    }
  }

  func viewControllerDidTapLearnMore(_ viewController: UIViewController) {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .dropBitMeLearnMore) else { return }
    self.openURL(url, completionHandler: nil)
  }

  func viewControllerDidTapShareOnTwitter(_ viewController: UIViewController) {
    let context = self.persistenceManager.viewContext
    guard let urlInfo = self.persistenceManager.brokers.user.getUserPublicURLInfo(in: context),
      let handle = urlInfo.primaryIdentity?.handle,
      let url = CoinNinjaUrlFactory.buildUrl(for: .dropBitMe(handle: handle))
      else { return }

    viewController.dismiss(animated: true) {
      let message = "Pay me in #Bitcoin using my Dropbit.me \(url.absoluteString)"
      self.openTwitterURL(withMessage: message)
    }
  }

}
