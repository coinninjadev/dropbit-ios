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

  convenience init(gray value: CGFloat) {
    self.init(r: value, g: value, b: value)
  }

}
