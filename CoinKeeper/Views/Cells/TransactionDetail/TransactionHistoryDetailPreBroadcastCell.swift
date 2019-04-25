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
  @IBOutlet var messageContainerHeightConstraint: NSLayoutConstraint!

  override func load(with viewModel: TransactionHistoryDetailCellViewModel, delegate: TransactionHistoryDetailCellDelegate) {
    super.load(with: viewModel, delegate: delegate)
    messageLabel.text = viewModel.messageLabel
    messageContainer.isHidden = viewModel.messageLabel == nil
    messageLabel.isHidden = viewModel.messageLabel == nil
    messageContainerHeightConstraint.constant = messageLabel.intrinsicContentSize.height + 16
    setupProgressBar(with: viewModel)
    layoutIfNeeded()
  }
}
