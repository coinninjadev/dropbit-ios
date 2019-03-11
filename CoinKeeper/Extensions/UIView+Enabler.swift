//
//  UIView+Enabler.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

  var isViewDisabled: Bool {
    return isHidden && !isUserInteractionEnabled
  }

  var isViewEnabled: Bool {
    return !isHidden && isUserInteractionEnabled
  }

  func disable() {
    guard !isViewDisabled else { return }
    isHidden = true
    isUserInteractionEnabled = false
  }

  func enable() {
    guard !isViewEnabled else { return }
    isHidden = false
    isUserInteractionEnabled = true
  }
}
