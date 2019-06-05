//
//  UIColor+Theme.swift
//  DropBit
//
//  Created by Ben Winters on 6/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIColor {

  // MARK: Colors
  static var darkBlueText: UIColor { return UIColor(r: 36, g: 37, b: 54) }
  static var darkBlueBackground: UIColor { return darkBlueText }

  static var lightBlueTint: UIColor { return UIColor(r: 44, g: 209, b: 255) }
  static var primaryActionButton: UIColor { return lightBlueTint }

  static var successGreen: UIColor { return UIColor(r: 131, g: 207, b: 28) }
  static var bannerSuccess: UIColor { return successGreen }

  static var primaryActionButtonHighlighted: UIColor { return UIColor(r: 150, g: 219, b: 243) }

  static var bannerWarn: UIColor { return UIColor(r: 224, g: 177, b: 0) }

  static var darkPeach: UIColor { return UIColor(r: 231, g: 108, b: 108) }

  static var warning: UIColor { return UIColor(r: 235, g: 153, b: 57) }

  static var appleGreen: UIColor { return UIColor(r: 131, g: 207, b: 28) }

  static var mango: UIColor { return UIColor(r: 247, g: 158, b: 54) }

  // MARK: Grays
  static var darkGray: UIColor { return UIColor(r: 155, g: 155, b: 155) }
  static var grayText: UIColor { return darkGray }

  static var searchResultGrayText: UIColor { return UIColor(r: 172, g: 172, b: 172) }
  static var memoInfoText: UIColor { return searchResultGrayText }

  static var mediumGrayText: UIColor { return UIColor(r: 184, g: 184, b: 184) }

  static var graySeparator: UIColor { return UIColor(r: 216, g: 216, b: 216) }
  static var dragIndicator: UIColor { return searchResultGrayText }

  static var semiOpaquePopoverBackground: UIColor { return UIColor.black.withAlphaComponent(0.7) }

  static var backgroundDarkGray: UIColor { return UIColor(r: 224, g: 224, b: 224) }
  static var memoBorder: UIColor { return backgroundDarkGray }
  static var borderDarkGray: UIColor { return backgroundDarkGray }
  static var selectedCellBackground: UIColor { return backgroundDarkGray }

  static var lightGrayOutline: UIColor { return UIColor(r: 227, g: 227, b: 227) }
  static var lightGrayButtonBackground: UIColor { return lightGrayOutline }

  static var lightGrayText: UIColor { return UIColor(r: 244, g: 244, b: 244) }
  static var lightGrayBackground: UIColor { return lightGrayText }

  static var grayMemoBackground: UIColor { return UIColor(r: 247, g: 247, b: 247) }
  static var flagButtonBackground: UIColor { return grayMemoBackground }

  static var extraLightGrayBackground: UIColor { return UIColor(r: 250, g: 250, b: 250) }
  static var containerBackgroundGray: UIColor { return extraLightGrayBackground }
  static var verifyWordLightGray: UIColor { return extraLightGrayBackground }
  static var searchBarBackground: UIColor { return extraLightGrayBackground }

  static var whiteText: UIColor { return UIColor(r: 255, g: 255, b: 255) }
  static var whiteBackground: UIColor { return whiteText }

}
