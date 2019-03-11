//
//  UIScreen+RelativeSize.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIScreen {

  enum RelativeSize {
    case tall, short
  }

  var relativeSize: RelativeSize {
    return bounds.height < 600 ? .short : .tall
  }
}
