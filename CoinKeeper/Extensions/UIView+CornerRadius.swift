//
//  UIView+CornerRadius.swift
//  DropBit
//
//  Created by Ben Winters on 5/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIView {

  func applyCornerRadius(_ radius: CGFloat) {
    self.layer.masksToBounds = true
    self.layer.cornerRadius = radius
  }

}
