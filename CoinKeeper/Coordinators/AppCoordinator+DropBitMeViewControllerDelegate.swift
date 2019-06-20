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
        try bgContext.save()
        if let urlInfo = self.persistenceManager.brokers.user.getUserPublicURLInfo(in: bgContext) {
          let avatarData = CKMUser.find(in: bgContext)?.avatar
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
              let config = DropBitMeConfig(state: state, userAvatarData: avatarData)
              dropbitMeVC.configure(with: config)
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
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .dropBitMeLearnMore) else { return }
    self.openURL(url, completionHandler: nil)
  }

  func viewControllerDidTapShareOnTwitter(_ viewController: UIViewController) {
    let context = self.persistenceManager.mainQueueContext()
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
