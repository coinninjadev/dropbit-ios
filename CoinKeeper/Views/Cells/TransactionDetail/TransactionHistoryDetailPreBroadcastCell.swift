//
//  TransactionHistoryDetailPreBroadcastCell.swift
//  DropBit
//
//  Created by BJ Miller on 4/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistoryDetailPreBroadcastCell: TransactionHistoryDetailValidBaseCell {

  @IBOutlet var messageContainer: TransactionDetailsInfoContainer!
  @IBOutlet var messageLabel: TransactionDetailMessageLabel!

  override func load(with viewModel: TransactionHistoryDetailCellViewModel, delegate: TransactionHistoryDetailCellDelegate) {
    super.load(with: viewModel, delegate: delegate)
    messageLabel.text = viewModel.messageLabel
    setupProgressBar(with: viewModel)
  }
}
