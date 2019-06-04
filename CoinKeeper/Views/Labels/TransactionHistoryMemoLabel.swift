//
//  TransactionHistoryMemoLabel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistoryMemoLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = CKFont.regular(14)
    textColor = .darkBlueText
    isHidden = true
    numberOfLines = 1
    textAlignment = .left
  }
}
