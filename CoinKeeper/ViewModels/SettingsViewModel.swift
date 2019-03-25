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
  let command: Command?
}

struct SettingsViewModel {
  let sectionViewModels: [SettingsSectionViewModel]
}

struct SettingsSectionViewModel {
  let headerViewModel: SettingsHeaderFooterViewModel?
  let cellViewModels: [SettingsCellViewModel]
  let footerViewModel: SettingsHeaderFooterViewModel?
}

struct SettingsCellViewModel {
  let type: SettingsCellType
  let command: Command?
}

enum SettingsCellType {
  case faqs
  case contactUs
  case termsOfUse
  case recoveryWords(Bool)
  case dustProtection(enabled: Bool)
  case privacyPolicy
  case licenses

  /// Returns nil if the text is conditional
  private var titleText: String? {
    switch self {
    case .faqs:           return "FAQs"
    case .recoveryWords:  return nil
    case .dustProtection: return "Dust Protection"
    case .contactUs:      return "Contact Us"
    case .termsOfUse:     return "Terms of Use"
    case .privacyPolicy:  return "Privacy Policy"
    case .licenses:       return "Open Source"
    }
  }

  var url: URL? {
    switch self {
    case .faqs:           return CoinNinjaUrlFactory.buildUrl(for: .faqs)
    case .contactUs:      return CoinNinjaUrlFactory.buildUrl(for: .contactUs)
    case .termsOfUse:     return CoinNinjaUrlFactory.buildUrl(for: .termsOfUse)
    case .privacyPolicy:  return CoinNinjaUrlFactory.buildUrl(for: .privacyPolicy)
    case .dustProtection: return CoinNinjaUrlFactory.buildUrl(for: .dustProtection)
    default:          return nil
    }
  }

  var attributedTitle: NSMutableAttributedString? {
    let fontSize = Theme.Font.settingsCellTitle.font.pointSize
    let textColor = Theme.Color.darkBlueText.color

    if let text = self.titleText {
      return NSMutableAttributedString.regular(text, size: fontSize, color: textColor)
    } else {
      switch self {
      case .recoveryWords(let verified):
        if verified {
          return NSMutableAttributedString.regular("Recovery Words", size: fontSize, color: textColor)
        } else {
          let mutableString = NSMutableAttributedString.regular("Recovery Words ", size: fontSize, color: textColor)
          mutableString.appendRegular("(Not Backed Up)", size: fontSize, color: Theme.Color.errorRed.color)
          return mutableString
        }
      default:
        return nil
      }
    }
  }

  var shouldShowDisclosureIndicator: Bool {
    switch self {
    default:                        return true
    }
  }

}
