//
//  TransactionDetailMessageLabel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 7/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionDetailMessageLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = CKFont.regular(13)
    textColor = .grayText
    isHidden = false
    textAlignment = .center
    numberOfLines = 0
  }
}
