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
    if isFirstTimeOpeningApp {
      analyticsManager.track(event: .firstOpen, with: nil)
      persistenceManager.set(true, for: .firstTimeOpeningApp)
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
      let isEnabled = self.persistenceManager.getUserPublicURLInfo(in: bgContext)?.isEnabled ?? false
      self.analyticsManager.track(property: MixpanelProperty(key: .isDropBitMeEnabled, value: isEnabled))
    }
  }

  func trackIfUserHasABalance() {
    let bgContext = persistenceManager.createBackgroundContext()
    guard let wmgr = walletManager else {
      self.analyticsManager.track(property: MixpanelProperty(key: .hasBTCBalance, value: false))
      return
    }

    var balanceIsPositive = false
    bgContext.performAndWait {
      balanceIsPositive = wmgr.spendableBalance(in: bgContext) > 0
    }

    analyticsManager.track(property: MixpanelProperty(key: .hasBTCBalance, value: balanceIsPositive ? true : false))
  }

}