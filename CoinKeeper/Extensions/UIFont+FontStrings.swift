//
//  UIFont+FontStrings.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIFont {
  convenience init(name: FontStrings, size: CGFloat) {
    self.init(name: name.rawValue, size: size)!
  }
}
