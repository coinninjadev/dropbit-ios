//
//  TransactionHistoryDetailValidCell.swift
//  DropBit
//
//  Created by BJ Miller on 4/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import JKSteppedProgressBar

/// Raw value is used as tag on bottom button
enum TransactionDetailAction: Int {
  case seeDetails = 0 //this matches the default tag value
  case cancelInvitation

  var buttonTitle: String? {
    switch self {
    case .cancelInvitation:  return "CANCEL DROPBIT"
    case .seeDetails:  return "DETAILS"
    }
  }
}

class TransactionHistoryDetailValidCell: TransactionHistoryDetailBaseCell {

  // MARK: outlets
  @IBOutlet var progressBarWidthConstraint: NSLayoutConstraint!
  @IBOutlet var progressView: SteppedProgressBar!
  @IBOutlet var addressView: TransactionHistoryDetailCellAddressView!
  @IBOutlet var bottomButton: TransactionDetailBottomButton!
  @IBOutlet var messageContainer: TransactionDetailsInfoContainer!
  @IBOutlet var messageLabel: TransactionDetailMessageLabel!
  @IBOutlet var messageContainerHeightConstraint: NSLayoutConstraint!

  // MARK: lifecycle
  override func load(with viewModel: TransactionHistoryDetailCellViewModel, delegate: TransactionHistoryDetailCellDelegate) {
    super.load(with: viewModel, delegate: delegate)
    messageLabel.text = viewModel.messageLabel
    messageContainer.isHidden = viewModel.messageLabel == nil
    messageLabel.isHidden = viewModel.messageLabel == nil
    messageContainerHeightConstraint.constant = messageLabel.intrinsicContentSize.height + 16
    setupProgressBar(with: viewModel)

    addressView.selectionDelegate = self
    addressView.load(with: viewModel)

    configureBottomButton(with: viewModel)

    layoutIfNeeded()
  }

  // MARK: actions
  @IBAction func didTapBottomButton(_ sender: UIButton) {
    guard let action = TransactionDetailAction(rawValue: sender.tag) else { return }
    delegate?.didTapBottomButton(detailCell: self, action: action)
  }

  // MARK: private methods
  private func configureBottomButton(with vm: TransactionHistoryDetailCellViewModel) {
    guard let action = vm.bottomButtonAction else {
      bottomButton.isHidden = true
      return
    }
    bottomButton.isHidden = false
    bottomButton.tag = action.rawValue
    bottomButton.setTitle(action.buttonTitle, for: .normal)

    switch action {
    case .cancelInvitation:
      bottomButton.backgroundColor = Theme.Color.errorRed.color
    case .seeDetails:
      bottomButton.backgroundColor = Theme.Color.darkBlueButton.color
    }
  }

  private func setupProgressBar(with viewModel: TransactionHistoryDetailCellViewModel) {
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
}

extension TransactionHistoryDetailValidCell: TransactionHistoryDetailAddressViewDelegate {
  func addressViewDidSelectAddress(_ addressView: TransactionHistoryDetailCellAddressView) {
    self.delegate?.didTapAddress(detailCell: self)
  }
}
