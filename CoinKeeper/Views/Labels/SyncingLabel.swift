//
//  SyncingLabel.swift
//  DropBit
//
//  Created by Larry Harmon on 1/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SyncingLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = Theme.Font.balanceSecondaryAmount.font
    textColor = Theme.Color.grayText.color
    isHidden = false
    numberOfLines = 1
    textAlignment = .right
  }
}
