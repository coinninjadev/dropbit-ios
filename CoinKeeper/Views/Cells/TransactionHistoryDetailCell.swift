//
//  TransactionHistoryDetailCell.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/11/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import JKSteppedProgressBar
import PromiseKit
import os.log

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

class TransactionHistoryDetailCell: TransactionHistoryDetailBaseCell {

  @IBOutlet var addressView: TransactionHistoryDetailCellAddressView!
  @IBOutlet var amountSummaryStack: UIStackView!
  @IBOutlet var messageContainer: TransactionDetailsInfoContainer!
  @IBOutlet var messageLabel: TransactionDetailMessageLabel!
  @IBOutlet var warningLabel: TransactionDetailWarningLabel!
  @IBOutlet var bottomButtonContainer: UIView!
  @IBOutlet var bottomButton: TransactionDetailBottomButton!
  @IBOutlet var progressView: SteppedProgressBar!
  @IBOutlet var bottomStackView: UIStackView!
  @IBOutlet var bottomStackViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet var progressBarWidthConstraint: NSLayoutConstraint!

  @IBAction func didTapBottomButton(_ sender: UIButton) {
    guard let action = TransactionDetailAction(rawValue: sender.tag) else {
      return
    }

    delegate?.didTapBottomButton(detailCell: self, action: action)
  }

  override func load(with vm: TransactionHistoryDetailCellViewModel, delegate: TransactionHistoryDetailCellDelegate) {
    viewModel = vm
    self.delegate = delegate

    statusLabel.text = vm.statusDescription
    statusLabel.textColor = vm.descriptionColor
    primaryAmountLabel.text = vm.primaryAmountLabel
    secondaryAmountLabel.attributedText = vm.secondaryAmountLabel
    dateLabel.text = vm.dateDescriptionFull

    incomingImage.image = vm.imageForTransactionDirection

    let isEqualToReceiverAddress = (vm.receiverAddress ?? "") == vm.counterpartyDescription
    counterpartyLabel.text = isEqualToReceiverAddress ? nil : vm.counterpartyDescription

    addressView.selectionDelegate = self
    addressView.load(with: vm)

    progressView.activeColor = Theme.Color.successGreen.color
    progressView.inactiveColor = Theme.Color.lightGrayText.color
    progressView.inactiveTextColor = progressView.inactiveColor
    progressView.stepFont = Theme.Font.progressBarNode.font

    setupProgressBar(with: vm)

    historicalValuesLabel.text = nil
    historicalValuesLabel.attributedText = vm.historicalAmountsAttributedString()

    messageLabel.text = vm.messageLabel
    messageContainer.isHidden = vm.messageLabel == nil
    messageLabel.isHidden = vm.messageLabel == nil
    warningLabel.isHidden = vm.warningMessageLabel == nil
    warningLabel.text = vm.warningMessageLabel

    configureBottomButton(with: vm)

    amountSummaryStack.isHidden = vm.broadcastFailed

    memoContainerView.isHidden = vm.memo.isEmpty
    addMemoButton.isHidden = !vm.memo.isEmpty

    memoContainerView.configure(memo: vm.memo, isShared: vm.memoWasShared, isSent: true,
                                isIncoming: vm.isIncoming, recipientName: nil)

    let visibleBottomElements = bottomStackView.arrangedSubviews.filter({!$0.isHidden}).count
    updateBottomStackConstraints(forElementCount: visibleBottomElements)
    layoutIfNeeded()
  }

  private func setupProgressBar(with viewModel: TransactionHistoryDetailCellViewModel) {
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

  private func configureBottomButton(with vm: TransactionHistoryDetailCellViewModel) {
    guard let action = vm.bottomButtonAction else {
      bottomButtonContainer.isHidden = true
      bottomButton.isHidden = true
      return
    }

    bottomButtonContainer.isHidden = false
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

  /**
   Reduces the height of the stack view depending on the number of visible
   arranged subviews, by adjusting its top constraint.
   */
  private func updateBottomStackConstraints(forElementCount count: Int) {
    // the stack view is a multiple of this,
    // though the visible view inside the element may be shorter and centered within the element
    let desiredElementHeight: CGFloat = 76

    bottomStackViewHeightConstraint.constant = desiredElementHeight * CGFloat(count)
  }

}

extension TransactionHistoryDetailCell: TransactionHistoryDetailAddressViewDelegate {
  func addressViewDidSelectAddress(_ addressView: TransactionHistoryDetailCellAddressView) {
    self.delegate?.didTapAddress(detailCell: self)
  }
}
