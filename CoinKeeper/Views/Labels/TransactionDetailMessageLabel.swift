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
    font = Theme.Font.transactionDetailAmountBreakdown.font
    textColor = Theme.Color.grayText.color
    isHidden = false
    textAlignment = .center
    numberOfLines = 0
  }
}
