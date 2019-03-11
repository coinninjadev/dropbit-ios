//
//  LightBorderedButton.swift
//  DropBit
//
//  Created by BJ Miller on 11/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class LightBorderedButton: UIButton {

  let defaultTitle = "What's it for?"

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .clear
    layer.cornerRadius = 5.0
    let borderColor = Theme.Color.grayText.color.withAlphaComponent(0.8)
    layer.borderColor = borderColor.cgColor
    layer.borderWidth = 0.5
    titleLabel?.font = Theme.Font.secondaryButtonTitle.font
    contentHorizontalAlignment = .center
    contentEdgeInsets = UIEdgeInsets(top: 0, left: 21, bottom: 0, right: 21)
    titleLabel?.lineBreakMode = .byTruncatingTail
    setTitle(defaultTitle, for: .normal)
    setTitleColor(borderColor, for: .normal)
    setTitleColor(Theme.Color.lightGrayText.color, for: .highlighted)
  }

  override func setTitle(_ title: String?, for state: State) {
    if let actualTitle = title, actualTitle.isNotEmpty {
      super.setTitle(actualTitle, for: state)
      setTitleColor(Theme.Color.darkBlueText.color, for: .normal)
    } else {
      super.setTitle(defaultTitle, for: state)
      setTitleColor(Theme.Color.grayText.color, for: .normal)
    }
  }
}
