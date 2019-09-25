//
//  TransactionHistoryDetailValidCell.swift
//  DropBit
//
//  Created by BJ Miller on 4/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import JKSteppedProgressBar

enum TransactionDetailAction {
  case seeDetails
  case cancelInvitation

  var buttonTitle: String? {
    switch self {
    case .cancelInvitation:  return "CANCEL DROPBIT"
    case .seeDetails:  return "MORE DETAILS"
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
  @IBOutlet var bottomBufferView: UIView!

  // MARK: lifecycle
  override func configure(with values: TransactionDetailCellDisplayable, delegate: TransactionHistoryDetailCellDelegate) {
    super.configure(with: values, delegate: delegate)
    messageLabel.text = values.messageText
    messageContainer.isHidden = values.shouldHideMessageLabel
    messageLabel.isHidden = values.shouldHideMessageLabel

    layoutIfNeeded()
    messageContainerHeightConstraint.constant = messageLabel.intrinsicContentSize.height + 20

//    setupProgressBar(with: viewModel)
//
//    addressView.selectionDelegate = self
//    addressView.load(with: viewModel)
//
//    configureBottomButton(with: viewModel)

    bottomBufferView.isHidden = (UIScreen.main.relativeSize == .short)
    layoutIfNeeded()
  }

  // MARK: actions
  @IBAction func didTapBottomButton(_ sender: UIButton) {
    delegate?.didTapBottomButton(detailCell: self)
  }

  // MARK: private methods
  private func configureBottomButton(with vm: OldTransactionDetailCellViewModel) {
    guard let action = vm.bottomButtonAction else {
      bottomButton.isHidden = true
      return
    }
    bottomButton.isHidden = false
    bottomButton.setTitle(action.buttonTitle, for: .normal)

    switch action {
    case .cancelInvitation:
      bottomButton.backgroundColor = .darkPeach
    case .seeDetails:
      bottomButton.backgroundColor = .darkBlueBackground
    }
  }

  private func setupProgressBar(with viewModel: OldTransactionDetailCellViewModel) {
    progressView.activeColor = .successGreen
    progressView.inactiveColor = .lightGrayText
    progressView.inactiveTextColor = progressView.inactiveColor
    progressView.stepFont = .semiBold(11)

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
