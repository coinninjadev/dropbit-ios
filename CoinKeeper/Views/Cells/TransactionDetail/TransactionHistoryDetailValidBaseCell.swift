//
//  TransactionHistoryDetailValidBaseCell.swift
//  DropBit
//
//  Created by BJ Miller on 4/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import JKSteppedProgressBar

class TransactionHistoryDetailValidBaseCell: TransactionHistoryDetailBaseCell {

  @IBOutlet var progressBarWidthConstraint: NSLayoutConstraint!
  @IBOutlet var progressView: SteppedProgressBar!
  @IBOutlet var addressView: TransactionHistoryDetailCellAddressView!

  func setupProgressBar(with viewModel: TransactionHistoryDetailCellViewModel) {
    progressView.activeColor = Theme.Color.successGreen.color
    progressView.inactiveColor = Theme.Color.lightGrayText.color
    progressView.inactiveTextColor = progressView.inactiveColor
    progressView.stepFont = Theme.Font.progressBarNode.font

    let shouldHide: Bool
    if viewModel.invitationStatus != nil {
      progressView.titles = ["", "", "", "", ""]
      progressView.stepTitles = ["1", "2", "3", "4", "✓"]
      progressBarWidthConstraint.constant = 250
    } else {
      progressView.titles = ["", "", ""]
      progressView.stepTitles = ["1", "2", "✓"]
      progressBarWidthConstraint.constant = 130
    }

    shouldHide = viewModel.broadcastFailed
    progressView.currentTab = viewModel.currentSelectedTab
    progressView.isHidden = shouldHide
  }

  override func load(with viewModel: TransactionHistoryDetailCellViewModel, delegate: TransactionHistoryDetailCellDelegate) {
    super.load(with: viewModel, delegate: delegate)

    addressView.selectionDelegate = self
    addressView.load(with: viewModel)
  }
}

extension TransactionHistoryDetailValidBaseCell: TransactionHistoryDetailAddressViewDelegate {
  func addressViewDidSelectAddress(_ addressView: TransactionHistoryDetailCellAddressView) {
//    self.delegate?.didTapAddress(detailCell: self)
  }
}
