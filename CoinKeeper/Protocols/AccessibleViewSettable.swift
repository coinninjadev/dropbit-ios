//
//  AccessibleViewSettable.swift
//  DropBit
//
//  Created by Ben Winters on 11/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

/// view should always be provided, but is optional for safely passing IBOutlets
typealias AccessibleViewElement = (view: UIAccessibilityIdentification?, element: AccessiblePageElement)

protocol AccessibleViewSettable: AnyObject {
  func accessibleViewsAndIdentifiers() -> [AccessibleViewElement]
}

extension AccessibleViewSettable {

  func setAccessibilityIdentifiers() {
    let pairs = accessibleViewsAndIdentifiers()
    for pair in pairs {
      pair.view?.setAccessibilityId(pair.element)
    }
  }

}
