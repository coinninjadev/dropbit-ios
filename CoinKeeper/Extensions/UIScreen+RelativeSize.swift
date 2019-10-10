//
//  UIScreen+RelativeSize.swift
//  DropBit
//
//  Created by BJ Miller on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIScreen {

  enum RelativeSize {
    case tall, medium, short
  }

  var relativeSize: RelativeSize {
    switch bounds.height {
    case 0..<600:     return .short //iPhone SE
    case 600..<700:   return .medium //iPhone 7, 8...
    default:          return .tall //iPhone 8 Plus, XR, 11 Pro Max...
    }
  }
}
