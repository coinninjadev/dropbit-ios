//
//  PrimaryActionButton.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class PrimaryActionButton: UIButton {

  enum Mode {
    case standard
    case error
  }

  var mode: Mode = .standard {
    didSet {
      setModeStyling()
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    layer.cornerRadius = 4.0
    titleLabel?.font = Theme.Font.primaryButtonTitle.font

    setModeStyling()
  }

  private func setModeStyling() {
    switch mode {
    case .standard:
      backgroundColor = Theme.Color.primaryActionButton.color
      setTitleColor(Theme.Color.lightGrayText.color, for: .normal)
      setTitleColor(Theme.Color.lightGrayText.color, for: .highlighted)
    case .error:
      backgroundColor = Theme.Color.errorRed.color
      setTitleColor(.white, for: .normal)
      setTitleColor(Theme.Color.lightGrayText.color, for: .highlighted)
    }
  }

  override var isHighlighted: Bool {
    didSet {
      var mainColor: UIColor

      switch mode {
      case .standard:
        mainColor = Theme.Color.primaryActionButton.color
      case .error:
        mainColor = Theme.Color.errorRed.color
      }

      backgroundColor = isHighlighted ? Theme.Color.lightGrayButtonBackground.color : mainColor
    }
  }
}
