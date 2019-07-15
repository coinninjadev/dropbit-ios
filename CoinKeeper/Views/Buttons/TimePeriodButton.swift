//
//  TimePeriodButton.swift
//  DropBit
//
//  Created by Mitchell Malleo on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class TimePeriodButton: UIButton {
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  private func initialize() {
    titleLabel?.font = .medium(10)
    backgroundColor = .lightGrayBackground
    tintColor = .darkBlueBackground
    layer.cornerRadius = 15.0
  }

  func selected() {
    backgroundColor = .darkBlueBackground
    tintColor = .white
  }

  func unselected() {
    backgroundColor = .lightGrayBackground
    tintColor = .darkBlueBackground
  }
}
