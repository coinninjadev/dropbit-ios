//
//  PrimaryActionButton.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class PrimaryActionButton: UIButton {

  enum Style {
    case standard
    case error
    case darkBlue
    case green
    case orange
  }

  var style: Style = .standard {
    didSet {
      setStyling()
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    applyCornerRadius(4)
    titleLabel?.font = Theme.Font.primaryButtonTitle.font

    setStyling()
  }

  private func setStyling() {
    switch style {
    case .standard:
      backgroundColor = Theme.Color.primaryActionButton.color
      setTitleColor(Theme.Color.lightGrayText.color, for: .normal)
      setTitleColor(Theme.Color.lightGrayText.color, for: .highlighted)
    case .error:
      backgroundColor = Theme.Color.red.color
      setTitleColor(.white, for: .normal)
      setTitleColor(Theme.Color.lightGrayText.color, for: .highlighted)
    case .darkBlue:
      backgroundColor = Theme.Color.darkBlueButton.color
      setTitleColor(Theme.Color.lightGrayText.color, for: .normal)
      setTitleColor(Theme.Color.lightGrayText.color, for: .highlighted)
    case .green:
      backgroundColor = Theme.Color.appleGreen.color
      setTitleColor(Theme.Color.lightGrayText.color, for: .normal)
      setTitleColor(Theme.Color.lightGrayText.color, for: .highlighted)
    case .orange:
      backgroundColor = Theme.Color.mango.color
      setTitleColor(Theme.Color.lightGrayText.color, for: .normal)
      setTitleColor(Theme.Color.lightGrayText.color, for: .highlighted)
    }
  }

  override var isHighlighted: Bool {
    didSet {
      var mainColor: UIColor

      switch style {
      case .standard:
        mainColor = Theme.Color.primaryActionButton.color
      case .error:
        mainColor = Theme.Color.red.color
      case .green: mainColor = Theme.Color.appleGreen.color
      case .darkBlue: mainColor = Theme.Color.darkBlueButton.color
      case .orange: mainColor = Theme.Color.mango.color
      }

      backgroundColor = isHighlighted ? Theme.Color.lightGrayButtonBackground.color : mainColor
    }
  }
}
