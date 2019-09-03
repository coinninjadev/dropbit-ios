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

  func load(with viewModel: TransactionInvalidDetailCellDisplayable, delegate: TransactionHistoryDetailCellDelegate) {
    super.load(with: viewModel, delegate: delegate)
    warningLabel.text = viewModel.warningMessage
    layoutIfNeeded()
  }
}
