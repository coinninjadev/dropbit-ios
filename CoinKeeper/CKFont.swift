//
//  CKFont.swift
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
      case .red: 												      return UIColor(r: 231, g: 108, b: 108)
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

  static var primaryButtonTitle: UIFont {
    return CKFont.medium(14)
  }

  static var compactButtonTitle: UIFont {
    return CKFont.medium(12)
  }

  static var secondaryButtonTitle: UIFont {
    return CKFont.regular(14)
  }

  static var popoverMessage: UIFont {
    return CKFont.regular(15)
  }

}
