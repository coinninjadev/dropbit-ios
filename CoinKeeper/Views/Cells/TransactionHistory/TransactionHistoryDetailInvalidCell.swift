//
//  TransactionHistoryDetailInvalidCell.swift
//  DropBit
//
//  Created by BJ Miller on 4/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistoryDetailInvalidCell: TransactionHistoryDetailBaseCell {

  // MARK: outlets
  @IBOutlet var warningLabel: TransactionDetailWarningLabel!

  func configure(with values: TransactionDetailInvalidCellDisplayable, delegate: TransactionHistoryDetailCellDelegate) {
    super.configure(with: values, delegate: delegate)
    warningLabel.text = values.warningMessage
    warningLabel.isHidden = values.shouldHideWarningMessage
    layoutIfNeeded()
  }
}
