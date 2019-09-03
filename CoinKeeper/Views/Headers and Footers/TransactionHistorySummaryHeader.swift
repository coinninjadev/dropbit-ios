//
//  TransactionHistorySummaryHeader.swift
//  DropBit
//
//  Created by Ben Winters on 9/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistorySummaryHeader: UICollectionReusableView {

  @IBOutlet var messageButton: UIButton!
  @IBOutlet var bottomConstraint: NSLayoutConstraint!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundColor = .clear
    messageButton.titleLabel?.font = .medium(16)
    messageButton.setTitleColor(.whiteText, for: .normal)
    messageButton.setTitleColor(.whiteText, for: .highlighted)
  }

  func configure(withMessage message: String, bgColor: UIColor) {
    messageButton.setTitle(message, for: .normal)
    messageButton.setTitle(message, for: .highlighted)
    messageButton.backgroundColor = bgColor
  }

}
