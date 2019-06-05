//
//  TransactionDetailWarningLabel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 7/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionDetailWarningLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = .regular(14)
    textColor = .red
    isHidden = false
    numberOfLines = 0
    textAlignment = .center
  }
}
