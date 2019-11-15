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
}

class QuickLoadControl: UIView {

  required init?(coder: NSCoder) {
    super.init(coder: coder)

    initialize()
  }

  private func initialize() {
    //set colors on button
  }

  func configure() {

  }
}
