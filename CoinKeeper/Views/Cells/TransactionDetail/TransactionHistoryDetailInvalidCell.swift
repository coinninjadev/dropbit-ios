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

  override func configure(with viewModel: OldTransactionDetailCellViewModel, delegate: TransactionHistoryDetailCellDelegate) {
    super.configure(with: viewModel, delegate: delegate)
    warningLabel.text = viewModel.warningMessageLabel
    layoutIfNeeded()
  }
}
