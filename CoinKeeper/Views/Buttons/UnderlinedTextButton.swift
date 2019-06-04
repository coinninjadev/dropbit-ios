//
//  UnderlinedTextButton.swift
//  CoinKeeper
//
//  Created by Ben Winters on 6/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class UnderlinedTextButton: UIButton {

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  /// `color` is used for the `.normal` state. `.highlighted` color is gray.
  func setUnderlinedTitle(_ text: String, size: CGFloat, color: UIColor) {
    let normalString = NSMutableAttributedString.medium(text, size: size, color: color)
    normalString.underlineText()

    let highlightedString = NSMutableAttributedString.medium(text, size: size, color: .grayText)
    highlightedString.underlineText()

    setAttributedTitle(normalString, for: .normal)
    setAttributedTitle(highlightedString, for: .highlighted)
  }

}
