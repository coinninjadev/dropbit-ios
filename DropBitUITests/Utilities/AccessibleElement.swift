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
  var rawValue: String { get }

  /// There is a default implementation, but this can be overridden if a custom pageName is needed.
  var pageName: String { get }
}

extension AccessibleElement {

  var pageName: String {
    let typeDesc = String(describing: Self.self)
    return typeDesc.replacingOccurrences(of: "Element", with: "")
  }

  var identifier: String {
    return pageName + "_" + self.rawValue
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
  case requestPay(RequestPayElement)
  case recoveryWordsIntro(RecoveryWordsIntroElement)
  case bannerMessage(SwiftMessagesBannerElement)
  case backupRecoveryWordsCell(BackupRecoveryWordsCellElement)
  case verifyRecoveryWordsCell(VerifyRecoveryWordsCellElement)
  case memoEntry(MemoEntryElement)
  case sendPayment(SendPaymentElement)
  case lightningUpgradeStart(LightningUpgradeStartElement)

  var identifier: String {
    switch self {
    case .tutorial(let element):                  return element.identifier
    case .start(let element):                     return element.identifier
    case .pinCreation(let element):               return element.identifier
    case .pinEntry(let element):                  return element.identifier
    case .successFail(let element):               return element.identifier
    case .createRecoveryWords(let element):       return element.identifier
    case .restoreWallet(let element):             return element.identifier
    case .walletOverview(let element):            return element.identifier
    case .deviceVerification(let element):        return element.identifier
    case .actionableAlert(let element):           return element.identifier
    case .requestPay(let element):                return element.identifier
    case .recoveryWordsIntro(let element):        return element.identifier
    case .bannerMessage(let element):             return element.identifier
    case .backupRecoveryWordsCell(let element):   return element.identifier
    case .verifyRecoveryWordsCell(let element):   return element.identifier
    case .memoEntry(let element):                 return element.identifier
    case .sendPayment(let element):               return element.identifier
    case .transactionHistory(let element):        return element.identifier
    case .lightningUpgradeStart(let element):     return element.identifier
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
}

enum ActionableAlertElement: String, AccessibleElement {
  case page
  case actionButton
}

enum TransactionHistoryElement: String, AccessibleElement {
  case page
  case menu
  case tutorialButton
  case receiveButton
  case sendButton
}

enum RequestPayElement: String, AccessibleElement {
  case page
  case addressLabel
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
