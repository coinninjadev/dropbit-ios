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

  static var neonGreen: UIColor { return UIColor(r: 69, g: 216, b: 136) }

  static var darkPeach: UIColor { return UIColor(r: 231, g: 108, b: 108) }

  static var lightningBlue: UIColor { return UIColor(r: 50, g: 50, b: 165) }

  static var bitcoinOrange: UIColor { return UIColor(r: 246, g: 151, b: 71) }

  static var warning: UIColor { return UIColor(r: 235, g: 153, b: 57) }

  static var appleGreen: UIColor { return UIColor(r: 131, g: 207, b: 28) }

  static var mango: UIColor { return UIColor(r: 247, g: 158, b: 54) }

  // MARK: Grays
  static var outgoingGray: UIColor { return UIColor(gray: 74) }

  static var darkGrayBackground: UIColor { return darkGrayText }
  static var darkGrayText: UIColor { return UIColor(gray: 155) }
  static var dragIndicator: UIColor { return darkGrayText }

  static var pageIndicator: UIColor { return UIColor(gray: 184) }
  static var deselectedGrayText: UIColor { return pageIndicator }

  static var graySeparator: UIColor { return UIColor(gray: 216) }

  static var semiOpaquePopoverBackground: UIColor { return UIColor.black.withAlphaComponent(0.7) }

  static var mediumGrayBackground: UIColor { return UIColor(gray: 224) }
  static var mediumGrayBorder: UIColor { return mediumGrayBackground }

  static var lightGrayBackground: UIColor { return UIColor(gray: 244) }
  static var lightGrayText: UIColor { return lightGrayBackground }

  static var extraLightGrayBackground: UIColor { return UIColor(gray: 250) }
  static var extraLightGrayText: UIColor { return extraLightGrayBackground }

  static var whiteText: UIColor { return UIColor(gray: 255) }
  static var whiteBackground: UIColor { return whiteText }

}
