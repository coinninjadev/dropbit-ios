//
//  TransactionHistoryCounterpartyLabel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistoryReceiverLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = Theme.Font.transactionHistoryReceiver.font
    textColor = Theme.Color.darkBlueText.color
    isHidden = false
    numberOfLines = 1
    textAlignment = .left
  }
}
