//
//  LimitEditTextField.swift
//  DropBit
//
//  Created by Mitchell on 7/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class PrimaryAmountTextField: UITextField {

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = UIColor.clear
    textColor = .darkBlueText
    keyboardType = .decimalPad
    font = .regular(30)
  }

}
