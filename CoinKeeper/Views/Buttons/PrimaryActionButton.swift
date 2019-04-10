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
    case learnBitcoin
    case getBitcoin
    case spendBitcoin
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
    case .learnBitcoin:
      backgroundColor = Theme.Color.darkBlueButton.color
      setTitleColor(Theme.Color.lightGrayText.color, for: .normal)
      setTitleColor(Theme.Color.lightGrayText.color, for: .highlighted)
    case .getBitcoin:
      backgroundColor = Theme.Color.appleGreen.color
      setTitleColor(Theme.Color.lightGrayText.color, for: .normal)
      setTitleColor(Theme.Color.lightGrayText.color, for: .highlighted)
    case .spendBitcoin:
      backgroundColor = Theme.Color.mango.color
      setTitleColor(Theme.Color.lightGrayText.color, for: .normal)
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
      case .getBitcoin: mainColor = Theme.Color.appleGreen.color
      case .learnBitcoin: mainColor = Theme.Color.darkBlueButton.color
      case .spendBitcoin: mainColor = Theme.Color.mango.color
      }

      backgroundColor = isHighlighted ? Theme.Color.lightGrayButtonBackground.color : mainColor
    }
  }
}
