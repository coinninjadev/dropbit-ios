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
    trackGenericPlatform()
    trackEventForFirstTimeOpeningAppIfApplicable()
    trackIfUserHasWallet()
    trackIfUserHasWordsBackedUp()
    trackIfDropBitMeIsEnabled()
  }

  func trackGenericPlatform() {
    analyticsManager.track(property: MixpanelProperty(key: .platform, value: "iOS"))

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
    var lightningBalance = 0
    bgContext.performAndWait {
      balance = wmgr.spendableBalance(in: bgContext).onChain
      lightningBalance = wmgr.spendableBalance(in: bgContext).lightning
    }

    let balanceIsPositive = balance > 0
    let lightningBalanceIsPositive = lightningBalance > 0
    analyticsManager.track(property: MixpanelProperty(key: .hasBTCBalance, value: balanceIsPositive))
    analyticsManager.track(property: MixpanelProperty(key: .hasLightningBalance, value: lightningBalanceIsPositive))
    analyticsManager.track(property: MixpanelProperty(key: .relativeWalletRange, value: AnalyticsRelativeWalletRange(satoshis: balance).rawValue))
  }

}
