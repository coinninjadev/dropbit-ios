//
//  SettingsCellViewModel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 6/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

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

  func didToggle(control: UISwitch) {
    switch type {
    case .dustProtection(enabled: _, infoAction: _, onChange: let onChange):
      onChange(control.isOn)
    case .yearlyHighPushNotification(enabled: _, onChange: let onChange):
      onChange(control.isOn)
    case .licenses, .recoveryWords:
      break
    }
  }

  func showInfo() {
    switch type {
    case .dustProtection(enabled: _, infoAction: let infoAction, onChange: _):
      infoAction(type)
    case .licenses, .recoveryWords, .yearlyHighPushNotification:
      break
    }
  }

  func didTapRow() {
    switch type {
    case .recoveryWords(_, action: let action):
      action()
    case .licenses(action: let action):
      action()
    case .dustProtection, .yearlyHighPushNotification:
      break
    }
  }
}

enum SettingsCellType {
  case recoveryWords(Bool, action: () -> Void)
  case dustProtection(enabled: Bool, infoAction: (SettingsCellType) -> Void, onChange: (Bool) -> Void)
  case yearlyHighPushNotification(enabled: Bool, onChange: (Bool) -> Void)
  case licenses(action: () -> Void)

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
    case .recoveryWords(let isBackedUp, _): return isBackedUp ? nil : "(Not Backed Up)"
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
    case .dustProtection(let isEnabled, _, _),
         .yearlyHighPushNotification(let isEnabled, _):
      return isEnabled
    default:
      return false
    }
  }

}
