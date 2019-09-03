//
//  UIFont+Theme.swift
//  DropBit
//
//  Created by BJ Miller on 2/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIFont {

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
    return .medium(14)
  }

  static var compactButtonTitle: UIFont {
    return .medium(12)
  }

  static var secondaryButtonTitle: UIFont {
    return .regular(14)
  }

  static var popoverMessage: UIFont {
    return .regular(15)
  }

}
