//
//  UIColor+Init.swift
//  DropBit
//
//  Created by Ben Winters on 1/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIColor {

  convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
    self.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
  }

  convenience init(gray value: CGFloat, alpha: CGFloat = 1.0) {
    self.init(r: value, g: value, b: value, a: alpha)
  }

  convenience init?(hex: String) {
    var sanitizedString = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    if sanitizedString.hasPrefix("#") {
      sanitizedString.remove(at: sanitizedString.startIndex)
    }

    let hexCharacterSet = CharacterSet(charactersIn: "1234567890abcdef")
    guard sanitizedString.rangeOfCharacter(from: hexCharacterSet) != nil else { return nil }

    var rgbValue: UInt64 = 0
    Scanner(string: sanitizedString).scanHexInt64(&rgbValue)

    self.init(
      red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
      alpha: CGFloat(1.0)
    )
  }

}
