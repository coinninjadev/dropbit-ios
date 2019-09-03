//
//  TransactionHistorySummaryHeader.swift
//  DropBit
//
//  Created by Ben Winters on 9/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistorySummaryHeader: UICollectionReusableView {

  private var messageLabel: UILabel!

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  private func initialize() {
    messageLabel.font = .medium(16)
    messageLabel.textColor = .whiteText
  }

  private func configure(withMessage message: String, bgColor: UIColor) {
    messageLabel.text = message
    self.backgroundColor = bgColor
  }

}
