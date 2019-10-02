//
//  PaddedLabel.swift
//  DropBit
//
//  Created by Ben Winters on 10/2/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class PaddedLabel: UILabel {

  let padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: padding))
  }

  override var intrinsicContentSize: CGSize { // override for Auto Layout
    let superContentSize = super.intrinsicContentSize
    let width = superContentSize.width + padding.left + padding.right
    let heigth = superContentSize.height + padding.top + padding.bottom
    return CGSize(width: width, height: heigth)
  }

}
