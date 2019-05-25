//
//  Theme.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

struct Theme {
  enum Color {
    case lightBlueTint
    case primaryActionButton
    case primaryActionButtonHighlighted
    case grayMemoBackground
    case confirmPaymentMemo
    case darkBlueButton, darkBlueText
    case lightGrayOutline, lightGrayButtonBackground
    case memoBorder
    case memoInfoText
    case whiteText
    case whiteBackground
    case grayText
    case mediumGrayText
    case flagButtonBackground
    case searchResultGrayText
    case graySeparator
    case selectedCellBackground
    case lightGrayBackground, lightGrayText
    case extraLightGrayBackground
    case red
    case verifyWordLightGray
    case settingsDarkGray, sendingToDarkGray
    case containerBackgroundGray
    case borderDarkGray
    case backgroundDarkGray
    case darkGray
    case sendPaymentNetworkFee
    case successGreen
    case searchBarLightGray
    case bannerSuccess
    case bannerWarn
    case warning
    case dragIndiciator
    case appleGreen
    case mango
    case semiOpaquePopoverBackground

    var color: UIColor {
      switch self {
      case .settingsDarkGray,
           .sendingToDarkGray: 								return UIColor(red: 0.14, green: 0.15, blue: 0.20, alpha: 1.00)
      case .searchBarLightGray: 							return UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.00)
      case .semiOpaquePopoverBackground:      return UIColor.black.withAlphaComponent(0.7)
      case .darkBlueButton,
           .darkBlueText,
           .confirmPaymentMemo,
           .sendPaymentNetworkFee:						return UIColor(r: 36, g: 37, b: 54)
      case .lightBlueTint,
           .primaryActionButton: 							return UIColor(r: 44, g: 209, b: 255)
      case .successGreen,
           .bannerSuccess: 										return UIColor(r: 131, g: 207, b: 28)
      case .primaryActionButtonHighlighted: 	return UIColor(r: 150, g: 219, b: 243)
      case .darkGray,
           .grayText: 												return UIColor(r: 155, g: 155, b: 155)
      case .searchResultGrayText,
           .memoInfoText: 										return UIColor(r: 172, g: 172, b: 172)
      case .mediumGrayText: 									return UIColor(r: 184, g: 184, b: 184)
      case .graySeparator,
           .dragIndiciator:										return UIColor(r: 216, g: 216, b: 216)
      case .bannerWarn: 											return UIColor(r: 224, g: 177, b: 0)
      case .memoBorder,
           .borderDarkGray,
           .backgroundDarkGray,
           .selectedCellBackground: 					return UIColor(r: 224, g: 224, b: 224)
      case .lightGrayOutline,
           .lightGrayButtonBackground: 				return UIColor(r: 227, g: 227, b: 227)
      case .red: 												return UIColor(r: 231, g: 108, b: 108)
      case .warning: 													return UIColor(r: 235, g: 153, b: 57)
      case .lightGrayBackground,
           .lightGrayText: 										return UIColor(r: 244, g: 244, b: 244)
      case .flagButtonBackground,
           .grayMemoBackground:								return UIColor(r: 247, g: 247, b: 247)
      case .extraLightGrayBackground,
           .containerBackgroundGray,
           .verifyWordLightGray: 							return UIColor(r: 250, g: 250, b: 250)
      case .whiteText,
           .whiteBackground:									return UIColor(r: 255, g: 255, b: 255)
      case .appleGreen:                       return UIColor(r: 131, g: 207, b: 28)
      case .mango:                            return UIColor(r: 247, g: 158, b: 54)
      }
    }
  }

  enum Font {
    case confirmPaymentMemo
    case confirmPaymentSecondaryAddress
    case addMemoTitle
    case balancePrimaryAmount
    case balanceSecondaryAmount
    case bannerMessage
    case keypadButton
    case onboardingTitle, onboardingSubtitle
    case examplePhoneNumber
    case createRecoveryWord, createRecoveryWordStatus
    case currencyButton
    case primaryButtonTitle
    case compactButtonTitle
    case secondaryButtonTitle
    case alertActionTitle, alertTitle
    case settingsVersion
    case settingsTitle
    case settingsPrice
    case settingsCellTitle
    case settingsSectionHeader
    case smallInfoLabel
    case requestPayPrimaryCurrency
    case requestPaySecondaryCurrency
    case requestPayAddress
    case transactionHistoryPrimaryAmount
    case transactionHistorySecondaryAmount
    case transactionHistoryReceiver
    case transactionHistoryDetail
    case transactionHistoryMemo
    case transactionDetailStatus
    case transactionDetailCounterparty
    case transactionDetailAddress
    case transactionDetailPrimaryAmount
    case transactionDetailSecondaryAmount
    case transactionDetailAmountBreakdown
    case transactionDetailDate
    case transactionDetailWarning
    case sendPaymentTitle
    case sendPaymentNetworkFee
    case sendingAmountPrimary
    case sendingBitcoinAmount
    case sendingAmountTo
    case sendingAmountToAddress
    case sendingAmountToPhoneNumber
    case tapReminderTitle
    case confirmPinTitle
    case deviceVerificationPhoneNumber
    case deviceVerificationCode
    case passFailTitle
    case passFailSubtitle
    case searchPlaceholderLabel
    case inviteHeaderTitle
    case contactTitle
    case skipButton
    case noConnectionError
    case deleteWalletTitle
    case settingTitle
    case phoneNumberDetail
    case walletRecoveryDetail
    case wordCountDetail
    case selectWordDetail
    case backToPreviousWord
    case noTransactionsTitle
    case noTransactionsDetail
    case disclaimerText
    case tutorialTitle
    case tutorialDetail
    case lockoutError
    case alertDetails
    case phoneNumberEntry
    case phoneNumberStatusTitle
    case phoneNumberStatusPrivacy
    case phoneNumberStatus
    case removeNumberError
    case addressesStored
    case collectionReusableFooter
    case serverAddress
    case serverAddressTitle
    case recoverySubtitle1
    case recoverySubtitle2
    case progressBarNode
    case shareTransactionTitle
    case searchResultText
    case shareTransactionMessage
    case copiedAddress
    case popoverMessage
    case popoverActionButton
    case verificationIdentity
    case verificationActionTitle
    case popoverSecondaryButton
    case popoverStatusLabel
    case restoreWalletButton

    var font: UIFont {
      switch self {
      // Light
      case .settingsVersion:										return CKFont.light(10)
      case .sendPaymentNetworkFee:							return CKFont.light(11)
      case .settingsTitle: 											return CKFont.light(11.6)
      case .settingTitle,
           .phoneNumberStatusPrivacy,
           .phoneNumberDetail: 									return CKFont.light(13)
      case .sendingBitcoinAmount,
           .walletRecoveryDetail: 							return CKFont.light(15)
      case .verificationIdentity:               return CKFont.light(18)

      // Regular
      case .transactionHistorySecondaryAmount,
           .searchResultText,
           .disclaimerText: 										return CKFont.regular(10)
      case .settingsCellTitle,
           .transactionHistoryDetail,
           .wordCountDetail,
           .copiedAddress,
           .restoreWalletButton,
           .selectWordDetail: 									return CKFont.regular(12)
      case .bannerMessage,
           .transactionDetailAmountBreakdown,
           .transactionDetailDate,
           .recoverySubtitle2,
           .confirmPaymentSecondaryAddress,
           .examplePhoneNumber,
           .tutorialDetail: 										return CKFont.regular(13)
      case .transactionHistoryMemo,
           .transactionDetailStatus,
           .confirmPaymentMemo,
           .transactionDetailWarning,
           .serverAddressTitle,
           .alertDetails,
           .phoneNumberEntry,
           .secondaryButtonTitle: 							return CKFont.regular(14)
      case .onboardingSubtitle,
           .balanceSecondaryAmount,
           .sendPaymentTitle,
           .transactionDetailSecondaryAmount,
           .confirmPinTitle,
           .skipButton,
           .addMemoTitle,
           .noConnectionError,
           .phoneNumberStatusTitle,
           .lockoutError,
           .passFailSubtitle,
           .popoverMessage,
           .noTransactionsDetail: 							return CKFont.regular(15)
      case .settingsPrice: 											return CKFont.regular(16)
      case .requestPaySecondaryCurrency,
           .verificationActionTitle:     				return CKFont.regular(17)
      case .sendingAmountToPhoneNumber:         return CKFont.regular(20)
      case .sendingAmountTo: 										return CKFont.regular(26)
      case .deviceVerificationPhoneNumber:			return CKFont.regular(28)
      case .deviceVerificationCode: 						return CKFont.regular(38)
      case .sendingAmountPrimary: 							return CKFont.regular(30)
      case .requestPayPrimaryCurrency: 					return CKFont.regular(35)

      // Medium
      case .smallInfoLabel: 										return CKFont.medium(10)
      case .compactButtonTitle,
           .searchPlaceholderLabel,
           .collectionReusableFooter,
           .inviteHeaderTitle: 									return CKFont.medium(12)
      case .alertTitle,
           .transactionDetailAddress,
           .serverAddress,
           .tapReminderTitle: 									return CKFont.medium(13)
      case .createRecoveryWordStatus,
           .primaryButtonTitle,
           .transactionHistoryReceiver,
           .removeNumberError,
           .sendingAmountToAddress,
           .backToPreviousWord: 								return CKFont.medium(14)
      case .contactTitle,
           .recoverySubtitle1,
           .deleteWalletTitle: 									return CKFont.medium(15)
      case .transactionHistoryPrimaryAmount: 		return CKFont.medium(16)
      case .shareTransactionMessage:            return CKFont.medium(17)
      case .onboardingTitle,
           .addressesStored,
           .balancePrimaryAmount: 							return CKFont.medium(19)
      case .passFailTitle,
           .noTransactionsTitle,
           .tutorialTitle: 											return CKFont.medium(20)
      case .transactionDetailCounterparty: 			return CKFont.medium(22)
      case .transactionDetailPrimaryAmount: 		return CKFont.medium(50)

      // Semi-Bold
      case .progressBarNode: 										return CKFont.semiBold(11)
      case .popoverSecondaryButton:             return CKFont.semiBold(12)
      case .alertActionTitle,
           .requestPayAddress: 									return CKFont.semiBold(13)
      case .settingsSectionHeader,
           .popoverActionButton,
           .popoverStatusLabel,
           .shareTransactionTitle: 							return CKFont.semiBold(14)
      case .phoneNumberStatus: 									return CKFont.semiBold(25)
      case .keypadButton: 											return CKFont.semiBold(28)

      // Bold
      case .currencyButton: 										return CKFont.bold(14)
      case .createRecoveryWord: 								return CKFont.bold(35)
      }
    }
  }
}

struct CKFont {

  static func light(_ size: CGFloat) -> UIFont {
    return UIFont(name: .montserratLight, size: size)
  }

  static func regular(_ size: CGFloat) -> UIFont {
    return UIFont(name: .montserratRegular, size: size)
  }

  static func medium(_ size: CGFloat) -> UIFont {
    return UIFont(name: .montserratMedium, size: size)
  }

  static func semiBold(_ size: CGFloat) -> UIFont {
    return UIFont(name: .montserratSemiBold, size: size)
  }

  static func bold(_ size: CGFloat) -> UIFont {
    return UIFont(name: .montserratBold, size: size)
  }

}
