//
//  UIView+AccessibilityIdentifier.swift
//  DropBit
//
//  Created by Ben Winters on 11/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIAccessibilityIdentification {

  func setAccessibilityId(_ element: AccessiblePageElement) {
    self.accessibilityIdentifier = element.identifier
  }

}
