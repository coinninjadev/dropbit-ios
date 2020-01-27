//
//  AccessibleElement.swift
//  DropBitUITests
//
//  Created by Ben Winters on 11/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

/**
 Avoid importing XCTest. These accessibility identifiers need to be accessible by the main application as well as DropBitUITests.
 */

/**
 In addition to the requirements below, each conforming enum should define a `page` case.
 Example: setViewControllerAccessibilityId(.restoreWallet(.page))
 Also, each conforming enum should end it's type name with "Element"
 for the AccessibleElement extension to correctly return the `pageName`.
 */
protocol AccessibleElement {
  /// Used to create the suffix for the `identifier`
  var elementIdentifier: String { get }

  /// There is a default implementation, but this can be overridden if a custom pageName is needed.
  var pageName: String { get }
}

extension AccessibleElement where Self: RawRepresentable {

  var elementIdentifier: String {
    return String(describing: rawValue)
  }

}

extension AccessibleElement {

  var pageName: String {
    let typeDesc = String(describing: Self.self)
    return typeDesc.replacingOccurrences(of: "Element", with: "")
  }

  var fullIdentifier: String {
    return pageName + "_" + self.elementIdentifier
  }

}

/**
 Each case corresponds to a view controller. The associated value is a string-backed enum
 case matching one of that view controller's UI elements.
 */
enum AccessiblePageElement {
  case tutorial(TutorialElement)
  case start(StartElement)
  case successFail(SuccessFailElement)
  case pinCreation(PinCreationElement)
  case pinEntry(PinEntryElement)
  case restoreWallet(RestoreWalletElement)
  case createRecoveryWords(BackupRecoveryWordsElement)
  case deviceVerification(DeviceVerificationElement)
  case walletOverview(WalletOverviewElement)
  case actionableAlert(ActionableAlertElement)
  case transactionHistory(TransactionHistoryElement)
  case transactionDetailCell(DetailCellElement)
  case requestPay(RequestPayElement)
  case recoveryWordsIntro(RecoveryWordsIntroElement)
  case bannerMessage(SwiftMessagesBannerElement)
  case backupRecoveryWordsCell(BackupRecoveryWordsCellElement)
  case verifyRecoveryWordsCell(VerifyRecoveryWordsCellElement)
  case memoEntry(MemoEntryElement)
  case sendPayment(SendPaymentElement)
  case lightningUpgradeStart(LightningUpgradeStartElement)
  case dropBitMe(DropBitMeElement)
  case drawer(DrawerElement)
  case getBitcoin(GetBitcoinElement)
  case earn(EarnElement)
  case settings(SettingsElement)
  case verificationStatus(VerificationStatusElement)
  case spend(SpendElement)
  case support(SupportElement)

  var identifier: String {
    switch self {
    case .tutorial(let element):                  return element.fullIdentifier
    case .start(let element):                     return element.fullIdentifier
    case .pinCreation(let element):               return element.fullIdentifier
    case .pinEntry(let element):                  return element.fullIdentifier
    case .successFail(let element):               return element.fullIdentifier
    case .createRecoveryWords(let element):       return element.fullIdentifier
    case .restoreWallet(let element):             return element.fullIdentifier
    case .walletOverview(let element):            return element.fullIdentifier
    case .deviceVerification(let element):        return element.fullIdentifier
    case .actionableAlert(let element):           return element.fullIdentifier
    case .requestPay(let element):                return element.fullIdentifier
    case .recoveryWordsIntro(let element):        return element.fullIdentifier
    case .bannerMessage(let element):             return element.fullIdentifier
    case .backupRecoveryWordsCell(let element):   return element.fullIdentifier
    case .verifyRecoveryWordsCell(let element):   return element.fullIdentifier
    case .memoEntry(let element):                 return element.fullIdentifier
    case .sendPayment(let element):               return element.fullIdentifier
    case .transactionHistory(let element):        return element.fullIdentifier
    case .transactionDetailCell(let element):     return element.fullIdentifier
    case .lightningUpgradeStart(let element):     return element.fullIdentifier
    case .dropBitMe(let element):                 return element.fullIdentifier
    case .drawer(let element):                    return element.fullIdentifier
    case .getBitcoin(let element):                return element.fullIdentifier
    case .earn(let element):                      return element.fullIdentifier
    case .settings(let element):                  return element.fullIdentifier
    case .verificationStatus(let element):        return element.fullIdentifier
    case .spend(let element):                     return element.fullIdentifier
    case .support(let element):                   return element.fullIdentifier
    }
  }

}

// MARK: - Page-specific UI element enums

enum BackupRecoveryWordsElement: String, AccessibleElement {
  case page
}

enum BackupRecoveryWordsCellElement: String, AccessibleElement {
  case page
  case wordLabel
}

enum DetailCellElement: String, AccessibleElement {
  case page
  case closeButton
}

enum VerifyRecoveryWordsCellElement: String, AccessibleElement {
  case page
  case currentIndexLabel
}

enum TutorialElement: String, AccessibleElement {
  case page
}

enum StartElement: String, AccessibleElement {
  case page
  case restoreWallet
  case newWallet
}

enum SuccessFailElement: String, AccessibleElement {
  case page
  case titleLabel
  case actionButton
}

enum PinCreationElement: String, AccessibleElement {
  case page
}

enum PinEntryElement: String, AccessibleElement {
  case page
}

enum RestoreWalletElement: String, AccessibleElement {
  case page
  case wordTextField
}

enum DeviceVerificationElement: String, AccessibleElement {
  case page
  case skipButton
}

enum WalletOverviewElement: String, AccessibleElement {
  case page
  case transactionHistory
  case menu
  case tutorialButton
  case receiveButton
  case sendButton
  case balanceView
  case bitcoinButton
  case lightningButton
}

enum ActionableAlertElement: String, AccessibleElement {
  case page
  case actionButton
}

enum TransactionHistoryElement: AccessibleElement {
  case page
  case menu
  case tutorialButton
  case receiveButton
  case sendButton
  case summaryCell(Int)
  case detailCell(Int)

  var elementIdentifier: String {
    switch self {
    case .page:                       return "page"
    case .menu:                       return "menu"
    case .tutorialButton:             return "tutorialButton"
    case .receiveButton:              return "receiveButton"
    case .sendButton:                 return "sendButton"
    case .summaryCell(let cellIndex): return "summaryCell_\(cellIndex)"
    case .detailCell(let cellIndex):  return "detailCell_\(cellIndex)"
    }
  }
}

enum RequestPayElement: String, AccessibleElement {
  case page
  case addressLabel
  case addAmountButton
  case editAmountTextField
  case bottomActionButton
  case qrImage
  case closeButton
}

enum RecoveryWordsIntroElement: String, AccessibleElement {
  case page
  case backup
  case skip
}

enum SwiftMessagesBannerElement: String, AccessibleElement {
  case page
  case close
  case titleLabel
}

enum MemoEntryElement: String, AccessibleElement {
  case page
}

enum SendPaymentElement: String, AccessibleElement {
  case page
  case memoLabel
}

enum LightningUpgradeStartElement: String, AccessibleElement {
  case page
  case startUpgradeButton
}

enum DropBitMeElement: String, AccessibleElement {
  case page
  case close
}

enum DrawerElement: String, AccessibleElement {
  case page
  case backupWords
  case getBitcoin
  case earn
  case settings
  case verify
  case spend
  case support
  case versionInfo
}

enum GetBitcoinElement: String, AccessibleElement {
  case page
}

enum EarnElement: String, AccessibleElement {
  case page
  case closeButton
}

enum SettingsElement: String, AccessibleElement {
  case page
  case closeButton
}

enum VerificationStatusElement: String, AccessibleElement {
  case page
  case closeButton
}

enum SpendElement: String, AccessibleElement {
  case page
}

enum SupportElement: String, AccessibleElement {
  case page
  case closeButton
}
