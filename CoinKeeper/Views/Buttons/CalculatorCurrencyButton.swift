//
//  CalculatorCurrencyButton.swift
//  CoinKeeper
//
//  Created by Ben Winters on 3/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

@IBDesignable class CalculatorCurrencyButton: UIButton {

  var underlineView = UIView()

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  private func initialize() {
    setTitleColor(Theme.Color.primaryActionButton.color, for: .selected)
    setTitleColor(Theme.Color.mediumGrayText.color, for: .normal)
    titleLabel?.font = Theme.Font.currencyButton.font
    backgroundColor = .clear
    tintColor = .clear
    adjustsImageWhenHighlighted = true

    addUnderlineView()
  }

  private func addUnderlineView() {
    let underlineHeight: CGFloat = 2
    let underlineWidth: CGFloat = 80
    let xOffset: CGFloat = (self.bounds.width - underlineWidth) / 2
    let yOffset: CGFloat = center.y + 16

    underlineView = UIView(frame: CGRect(x: xOffset, y: yOffset, width: underlineWidth, height: underlineHeight))
    underlineView.backgroundColor = Theme.Color.primaryActionButton.color
    addSubview(underlineView)
  }

  override var isSelected: Bool {
    willSet {
      underlineView.isHidden = !newValue
    }
  }

}
