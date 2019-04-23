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

  func setupProgressBar(with viewModel: TransactionHistoryDetailCellViewModel) {
    let shouldHide: Bool
    if let invitationStatus = viewModel.invitationStatus {
      progressView.titles = ["", "", "", "", ""]
      progressView.stepTitles = ["1", "2", "3", "4", "✓"]
      shouldHide = invitationStatus == .expired || invitationStatus == .canceled || viewModel.broadcastFailed
      progressBarWidthConstraint.constant = 250
    } else {
      progressView.titles = ["", "", ""]
      progressView.stepTitles = ["1", "2", "✓"]
      shouldHide = viewModel.broadcastFailed
      progressBarWidthConstraint.constant = 130
    }

    progressView.currentTab = viewModel.currentSelectedTab
    progressView.isHidden = shouldHide
  }
}
