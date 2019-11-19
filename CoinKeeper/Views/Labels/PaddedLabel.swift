//
//  PaddedLabel.swift
//  DropBit
//
//  Created by Ben Winters on 10/2/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class PaddedLabel: UILabel {

  let defaultPadding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

  var padding: UIEdgeInsets {
    return defaultPadding
  }

  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: padding))
  }

  override var intrinsicContentSize: CGSize { // override for Auto Layout
    let superContentSize = super.intrinsicContentSize
    let p = padding
    let width = superContentSize.width + p.left + p.right
    let heigth = superContentSize.height + p.top + p.bottom
    return CGSize(width: width, height: heigth)
  }

}
