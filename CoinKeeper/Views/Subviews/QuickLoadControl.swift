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
    confirmButton.configure(withStyle: .lightning)
  }

  func configure(title: String, index: Int, delegate: LongPressConfirmButtonDelegate) {
    titleLabel.text = title
    confirmButton.delegate = delegate
    confirmButton.tag = index
  }

}
