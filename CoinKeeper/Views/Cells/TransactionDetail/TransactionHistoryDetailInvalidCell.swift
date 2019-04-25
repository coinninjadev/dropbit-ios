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

  override func load(with viewModel: TransactionHistoryDetailCellViewModel, delegate: TransactionHistoryDetailCellDelegate) {
    super.load(with: viewModel, delegate: delegate)
    statusLabel.text = viewModel.statusDescription
    statusLabel.textColor = viewModel.descriptionColor
    warningLabel.text = viewModel.warningMessageLabel
    layoutIfNeeded()
  }
}
