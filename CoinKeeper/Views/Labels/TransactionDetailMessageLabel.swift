//
//  TransactionDetailMessageLabel.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionDetailMessageLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = .regular(13)
    textColor = .darkGrayText
    isHidden = false
    textAlignment = .center
    numberOfLines = 0
  }
}
