//
//  BadgeView.swift
//  DropBit
//
//  Created by Ben Winters on 10/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

/// A red dot to be added as a subview of the view to be badged.
class BadgeView: UIView {

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    backgroundColor = .red
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .red
  }

  convenience init() {
    let frame = BadgeView.standardFrame()
    self.init(frame: frame)
  }

  static let standardDiameter: CGFloat = 13

  static func standardFrame() -> CGRect {
    return CGRect(x: 0, y: 0, width: standardDiameter, height: standardDiameter)
  }

}
