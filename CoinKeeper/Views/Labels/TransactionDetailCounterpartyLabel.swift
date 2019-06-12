//
//  TransactionDetailCounterpartyLabel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionDetailCounterpartyLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = .medium(22)
    textColor = .darkBlueText
    isHidden = false
    numberOfLines = 1
    textAlignment = .center
  }
}
