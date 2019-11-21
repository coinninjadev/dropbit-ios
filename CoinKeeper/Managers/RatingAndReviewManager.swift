//
//  RatingAndReviewManager.swift
//  DropBit
//
//  Created by BJ Miller on 11/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import StoreKit

protocol RatingAndReviewManagerType {
  func promptForReviewIfNecessary(didReceiveFunds: Bool)
}

class RatingAndReviewManager: RatingAndReviewManagerType {
  // MARK: variables
  private weak var persistenceManager: PersistenceManagerType?

  // MARK: initializers
  init(persistenceManager: PersistenceManagerType) {
    self.persistenceManager = persistenceManager
  }

  // MARK: methods
  func promptForReviewIfNecessary(didReceiveFunds: Bool) {
    guard shouldPromptForReview(didReceiveFunds: didReceiveFunds) else { return }
    guard let pmgr = persistenceManager else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
      SKStoreReviewController.requestReview()
      pmgr.brokers.preferences.reviewLastRequestDate = Date()
      pmgr.brokers.preferences.reviewLastRequestVersion = VersionInfo().appVersion
    }
  }

  // MARK: private
  private func shouldPromptForReview(didReceiveFunds: Bool) -> Bool {
    guard let pmgr = persistenceManager else { return false }

    let now = Date()
    let installDate = pmgr.brokers.preferences.firstLaunchDate
    guard let installDatePlusBuffer = Calendar.current.date(byAdding: .day, value: 2, to: installDate) else { return false }

    let lastPromptedDate = pmgr.brokers.preferences.reviewLastRequestDate

    // first time and never prompted
    if installDatePlusBuffer < now && lastPromptedDate == nil {
      return true
    }

    // received funds, 48 hours after last attempt, different version
    guard let lastDate = lastPromptedDate,
      let lastDatePlusBuffer = Calendar.current.date(byAdding: .day, value: 2, to: lastDate) else { return false }

    let lastPromptedVersion = pmgr.brokers.preferences.reviewLastRequestVersion
    let currentVersion = VersionInfo().appVersion

    if didReceiveFunds && (currentVersion != lastPromptedVersion) && (lastDatePlusBuffer < now) {
      return true
    }

    return false
  }
}
