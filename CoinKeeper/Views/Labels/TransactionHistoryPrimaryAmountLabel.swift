//
//  TransactionHistoryAmountLabel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistoryPrimaryAmountLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = Theme.Font.transactionHistoryPrimaryAmount.font
    isHidden = false
    numberOfLines = 1
    textAlignment = .right
  }
}
