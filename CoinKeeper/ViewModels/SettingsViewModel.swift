//
//  SettingsCellViewModel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 6/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct SettingsHeaderFooterViewModel {
  let title: String
}

struct SettingsViewModel {
  let sectionViewModels: [SettingsSectionViewModel]
}

struct SettingsSectionViewModel {
  let headerViewModel: SettingsHeaderFooterViewModel?
  let cellViewModels: [SettingsCellViewModel]
}

struct SettingsCellViewModel {
  let type: SettingsCellType
  let command: Command?
}

enum SettingsCellType {
  case recoveryWords(Bool)
  case dustProtection(enabled: Bool)
  case yearlyHighPushNotification(enabled: Bool)
  case licenses

  /// Returns nil if the text is conditional
  var titleText: String {
    switch self {
    case .recoveryWords:  return "Recovery Words"
    case .dustProtection: return "Dust Protection"
    case .yearlyHighPushNotification: return "Bitcoin Yearly High Price Notification"
    case .licenses:       return "Open Source"
    }
  }

  var secondaryTitleText: String? {
    switch self {
    case .recoveryWords(let isBackedUp): return isBackedUp ? nil : "(Not Backed Up)"
    default: return nil
    }
  }

  var url: URL? {
    switch self {
    case .dustProtection: return CoinNinjaUrlFactory.buildUrl(for: .dustProtection)
    default:          return nil
    }
  }

  var switchIsOn: Bool {
    switch self {
    case .dustProtection(let isEnabled),
         .yearlyHighPushNotification(let isEnabled):
      return isEnabled
    default:
      return false
    }
  }

}
