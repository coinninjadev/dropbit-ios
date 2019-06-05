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
    titleLabel?.font = .primaryButtonTitle

    setStyling()
  }

  private func setStyling() {
    switch style {
    case .standard:
      backgroundColor = .primaryActionButton
      setTitleColor(.lightGrayText, for: .normal)
      setTitleColor(.lightGrayText, for: .highlighted)
    case .error:
      backgroundColor = .darkPeach
      setTitleColor(.white, for: .normal)
      setTitleColor(.lightGrayText, for: .highlighted)
    case .darkBlue:
      backgroundColor = .darkBlueBackground
      setTitleColor(.lightGrayText, for: .normal)
      setTitleColor(.lightGrayText, for: .highlighted)
    case .green:
      backgroundColor = .appleGreen
      setTitleColor(.lightGrayText, for: .normal)
      setTitleColor(.lightGrayText, for: .highlighted)
    case .orange:
      backgroundColor = .mango
      setTitleColor(.lightGrayText, for: .normal)
      setTitleColor(.lightGrayText, for: .highlighted)
    }
  }

  override var isHighlighted: Bool {
    didSet {
      var mainColor: UIColor

      switch style {
      case .standard:
        mainColor = .primaryActionButton
      case .error:
        mainColor = .darkPeach
      case .green: mainColor = .appleGreen
      case .darkBlue: mainColor = .darkBlueBackground
      case .orange: mainColor = .mango
      }

      backgroundColor = isHighlighted ? .lightGrayButtonBackground : mainColor
    }
  }
}
