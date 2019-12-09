//
//  VerticalCenterButton.swift
//  DropBit
//
//  Created by Mitchell Malleo on 12/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class VerticalCenterButton: UIButton {

  override func awakeFromNib() {
    super.awakeFromNib()
    centerVertically()

    imageView?.layer.borderColor = UIColor.neonGreen.cgColor
    imageView?.contentMode = .center
    titleLabel?.textAlignment = .center
    titleLabel?.font = .light(13)
    titleLabel?.adjustsFontSizeToFitWidth = true
    titleLabel?.minimumScaleFactor = 0.50
  }

  override var isSelected: Bool {
    willSet {
      if newValue {
        imageView?.layer.borderWidth = 3.0
        imageView?.applyCornerRadius(10)
      } else {
        imageView?.layer.borderWidth = 0.0
      }
    }
  }

  override func setTitle(_ title: String?, for state: UIControl.State) {
    super.setTitle(title, for: state)
    centerVertically()
  }
}
