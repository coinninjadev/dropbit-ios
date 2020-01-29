//
//  PrimaryActionButton.swift
//  DropBit
//
//  Created by BJ Miller on 3/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class PrimaryActionButton: UIButton {

  private var notHighlightedBackground: UIColor?

  override func awakeFromNib() {
    super.awakeFromNib()
    titleLabel?.font = .primaryButtonTitle
    applyStyle(.standard)
  }

  override var isHighlighted: Bool {
    didSet {
      backgroundColor = isHighlighted ? .mediumGrayBackground : notHighlightedBackground
    }
  }

  var style: PrimaryActionButtonStyle = .standard {
    didSet {
      applyStyle(style)
    }
  }

  private func applyStyle(_ style: PrimaryActionButtonStyle) {
    self.isEnabled = style.enabled
    self.backgroundColor = style.backgroundColor
    self.notHighlightedBackground = style.backgroundColor
    self.setTitleColor(style.normalTitleColor, for: .normal)
    self.setTitleColor(style.highlightedTitleColor, for: .highlighted)

    let radius: CGFloat = style.shouldRoundCorners ? 4 : 0
    self.applyCornerRadius(radius)

    if let tint = style.tintColor {
      self.tintColor = tint
      self.imageView?.tintColor = tint
    }
  }

}

class PrimaryActionButtonStyle {

  let normalTitleColor: UIColor
  let highlightedTitleColor: UIColor
  let backgroundColor: UIColor
  let tintColor: UIColor?
  let shouldRoundCorners: Bool
  let enabled: Bool

  init(normal: UIColor, highlighted: UIColor, background: UIColor,
       tint: UIColor?, rounded: Bool, enabled: Bool = true) {
    self.normalTitleColor = normal
    self.highlightedTitleColor = highlighted
    self.backgroundColor = background
    self.tintColor = tint
    self.shouldRoundCorners = rounded
    self.enabled = enabled
  }

  static var standard: PrimaryActionButtonStyle {
    return LightTextButtonStyle(background: .primaryActionButton)
  }

  static var error: PrimaryActionButtonStyle {
    return PrimaryActionButtonStyle(normal: .white, highlighted: .lightGrayText,
                                    background: .darkPeach, tint: nil, rounded: true)
  }

  static var darkBlue: PrimaryActionButtonStyle {
    return LightTextButtonStyle(background: .darkBlueBackground)
  }

  static var green: PrimaryActionButtonStyle {
    return LightTextButtonStyle(background: .appleGreen)
  }

  static var neonGreen: PrimaryActionButtonStyle {
    return LightTextButtonStyle(background: .neonGreen)
  }

  static var orange: PrimaryActionButtonStyle {
    return LightTextButtonStyle(background: .mango)
  }

  static func bitcoin(rounded: Bool) -> PrimaryActionButtonStyle {
    return WalletTransactionTypeStyle(background: .bitcoinOrange, rounded: rounded)
  }

  static func lightning(rounded: Bool) -> PrimaryActionButtonStyle {
    return WalletTransactionTypeStyle(background: .lightningBlue, rounded: rounded)
  }

  static func lightningUpgrade(enabled: Bool) -> PrimaryActionButtonStyle {
    let background: UIColor = enabled ? .white : UIColor.white.withAlphaComponent(0.4)
    return PrimaryActionButtonStyle(normal: .darkPurple, highlighted: .lightGrayText,
                                    background: background, tint: nil, rounded: true, enabled: enabled)
  }

  static var mediumPurple: PrimaryActionButtonStyle {
    return WhiteTintButtonStyle(normal: .white, highlighted: .lightGrayText,
                                background: .mediumPurple, rounded: true)
  }

  static var standardClear: PrimaryActionButtonStyle {
    return PrimaryActionButtonStyle(normal: .primaryActionButton, highlighted: .lightGrayText, background: .clear, tint: nil, rounded: true)
  }

  static var darkBlueClear: PrimaryActionButtonStyle {
    return PrimaryActionButtonStyle(normal: .darkBlueText, highlighted: .lightGrayText, background: .clear, tint: nil, rounded: true)
  }
}

class LightTextButtonStyle: PrimaryActionButtonStyle {
  init(background: UIColor, rounded: Bool = true) {
    super.init(normal: .lightGrayText, highlighted: .lightGrayText, background: background,
               tint: nil, rounded: rounded)
  }
}

class WhiteTintButtonStyle: PrimaryActionButtonStyle {
  init(normal: UIColor, highlighted: UIColor, background: UIColor, rounded: Bool) {
    super.init(normal: normal, highlighted: highlighted, background: background,
               tint: .white, rounded: rounded)
  }
}

class WalletTransactionTypeStyle: WhiteTintButtonStyle {
  init(background: UIColor, rounded: Bool) {
    super.init(normal: .white, highlighted: .lightGrayText, background: background, rounded: rounded)
  }
}
