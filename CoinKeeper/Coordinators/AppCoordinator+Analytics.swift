//
//  AppCoordinator+Analytics.swift
//  DropBit
//
//  Created by Ben Winters on 5/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension AppCoordinator {

  func trackAnalytics() {
    trackEventForFirstTimeOpeningAppIfApplicable()
    trackIfUserHasWallet()
    trackIfUserHasWordsBackedUp()
    trackIfDropBitMeIsEnabled()
  }

  func trackEventForFirstTimeOpeningAppIfApplicable() {
    if persistenceManager.brokers.activity.isFirstTimeOpeningApp {
      analyticsManager.track(event: .firstOpen, with: nil)
      persistenceManager.brokers.activity.isFirstTimeOpeningApp = false
    }
  }

  func trackIfUserHasWallet() {
    if walletManager == nil {
      analyticsManager.track(property: MixpanelProperty(key: .hasWallet, value: false))
    } else {
      analyticsManager.track(property: MixpanelProperty(key: .hasWallet, value: true))
    }
  }

  func trackIfUserHasWordsBackedUp() {
    if walletManager == nil || !wordsBackedUp {
      analyticsManager.track(property: MixpanelProperty(key: .wordsBackedUp, value: false))
    } else {
      analyticsManager.track(property: MixpanelProperty(key: .wordsBackedUp, value: true))
    }
  }

  func trackIfDropBitMeIsEnabled() {
    let bgContext = self.persistenceManager.createBackgroundContext()
    bgContext.perform {
      let isEnabled = self.persistenceManager.brokers.user.getUserPublicURLInfo(in: bgContext)?.isEnabled ?? false
      self.analyticsManager.track(property: MixpanelProperty(key: .isDropBitMeEnabled, value: isEnabled))
    }
  }

  func trackIfUserHasABalance() {
    let bgContext = persistenceManager.createBackgroundContext()
    guard let wmgr = walletManager else {
      self.analyticsManager.track(property: MixpanelProperty(key: .hasBTCBalance, value: false))
      return
    }

    var balance = 0
    bgContext.performAndWait {
      balance = wmgr.spendableBalance(in: bgContext)
    }

    let balanceIsPositive = balance > 0
    analyticsManager.track(property: MixpanelProperty(key: .hasBTCBalance, value: balanceIsPositive ? true : false))
    analyticsManager.track(property: MixpanelProperty(key: .relativeWalletRange, value: AnalyticsRelativeWalletRange(satoshis: balance).rawValue))
  }

}
