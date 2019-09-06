//
//  UIView+CornerRadius.swift
//  DropBit
//
//  Created by Ben Winters on 5/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension CACornerMask {
  static var all: CACornerMask {
    return [.layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            .layerMinXMaxYCorner,
            .layerMaxXMaxYCorner]
  }

  static var top: CACornerMask {
    return [.layerMinXMinYCorner,
            .layerMaxXMinYCorner]
  }

  static var none: CACornerMask {
    return []
  }
}

extension UIView {

  func applyCornerRadius(_ radius: CGFloat, toCorners corners: CACornerMask = .all) {
    self.layer.masksToBounds = true
    self.layer.cornerRadius = radius
    self.layer.maskedCorners = corners
  }

}
