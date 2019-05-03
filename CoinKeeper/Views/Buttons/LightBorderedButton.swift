//
//  LightBorderedButton.swift
//  DropBit
//
//  Created by BJ Miller on 11/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class LightBorderedButton: UIButton {

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .clear
    applyCornerRadius(5)
    let borderColor = Theme.Color.grayText.color.withAlphaComponent(0.8)
    layer.borderColor = borderColor.cgColor
    layer.borderWidth = 1.0 / UIScreen.main.nativeScale
    titleLabel?.font = Theme.Font.secondaryButtonTitle.font
    contentHorizontalAlignment = .center
    contentEdgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
    setTitleColor(borderColor, for: .normal)
    setTitleColor(Theme.Color.lightGrayText.color, for: .highlighted)
  }

}
