//
//  QuickLoadControl.swift
//  DropBit
//
//  Created by Ben Winters on 11/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

struct QuickLoadControlConfig {
  let isEnabled: Bool
  let amount: Money
  let isMax: Bool

  init(isEnabled: Bool, amount: Money) {
    self.isEnabled = isEnabled
    self.amount = amount
    self.isMax = false
  }

  init(maxAmount: Money) {
    self.isEnabled = true
    self.amount = maxAmount
    self.isMax = true
  }

  var displayAmount: String {
    let formatter: CKCurrencyFormatter
    if isMax {
      formatter = FiatFormatter(currency: amount.currency, withSymbol: true)
    } else {
      formatter = RoundedFiatFormatter(currency: amount.currency, withSymbol: true)
    }
    return formatter.string(fromDecimal: amount.amount) ?? "-"
  }

}

class QuickLoadControl: UIView {

  @IBOutlet var confirmButton: LongPressConfirmButton!
  @IBOutlet var titleLabel: UILabel!

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    xibSetup()
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
    initialize()
  }

  private func initialize() {
    titleLabel.font = .semiBold(20)
  }

  private func grayColor(_ isEnabled: Bool) -> UIColor {
    let standard: UIColor = .mediumGrayBackground
    return isEnabled ? standard : standard.withAlphaComponent(0.32)
  }

  func configure(title: String, index: Int, isEnabled: Bool, delegate: LongPressConfirmButtonDelegate) {
    let gray = grayColor(isEnabled)
    titleLabel.text = title
    titleLabel.textColor = gray
    confirmButton.delegate = delegate
    confirmButton.tag = index
    let buttonConfig = ConfirmButtonConfig(foregroundColor: .lightningBlue,
                                           backgroundColor: gray,
                                           scalingMethod: .minimal,
                                           secondsToConfirm: 1.5)
    confirmButton.configure(with: buttonConfig, delegate: delegate)
  }

}
