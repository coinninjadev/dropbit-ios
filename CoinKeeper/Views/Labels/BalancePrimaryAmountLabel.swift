//
//  BalancePrimaryAmountLabel.swift
//  DropBit
//
//  Created by Ben Winters on 4/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class BalancePrimaryAmountLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = .medium(19)
    textColor = .darkBlueText
    isHidden = false
    numberOfLines = 1
    textAlignment = .right
  }

  override func drawText(in rect: CGRect) {
    let insets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
    super.drawText(in: rect.inset(by: insets))
  }
}
