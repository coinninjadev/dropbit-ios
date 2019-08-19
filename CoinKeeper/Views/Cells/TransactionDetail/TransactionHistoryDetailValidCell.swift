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
  case removeInvoice

  var buttonTitle: String {
    switch self {
    case .seeDetails:
      return "DETAILS"
    case .cancelInvitation:
      return "CANCEL DROPBIT"
    case .removeInvoice:
      return "REMOVE FROM TRANSACTION LIST"
    }
  }
}

//TODO: resolve commented out implementations
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
  override func load(with viewModel: TransactionHistoryDetailCellDisplayable, delegate: TransactionHistoryDetailCellDelegate) {
    super.load(with: viewModel, delegate: delegate)
//    messageLabel.text = viewModel.messageLabel
//    messageContainer.isHidden = viewModel.messageLabel == nil
//    messageLabel.isHidden = viewModel.messageLabel == nil
//    layoutIfNeeded()
//    messageContainerHeightConstraint.constant = messageLabel.intrinsicContentSize.height + 20
//    setupProgressBar(with: viewModel)
//
//    addressView.selectionDelegate = self
//    addressView.load(with: viewModel)
//
//    configureBottomButton(with: viewModel)
//
//    bottomBufferView.isHidden = (UIScreen.main.relativeSize == .short)

    layoutIfNeeded()
  }

  // MARK: actions
  @IBAction func didTapBottomButton(_ sender: UIButton) {
    delegate.didTapBottomButton(detailCell: self)
  }

  // MARK: private methods
  private func configureBottomButton(with vm: TransactionHistoryDetailCellViewModel) {
    guard let action = vm.bottomButtonAction else {
      bottomButton.isHidden = true
      return
    }
    bottomButton.isHidden = false
    bottomButton.setTitle(action.buttonTitle, for: .normal)

//    switch action {
//    case .cancelInvitation:
//      bottomButton.backgroundColor = .darkPeach
//    case .seeDetails:
//      bottomButton.backgroundColor = .darkBlueBackground
//    }
  }

  private func setupProgressBar(with viewModel: TransactionHistoryDetailCellViewModel) {
//    progressView.activeColor = .successGreen
//    progressView.inactiveColor = .lightGrayText
//    progressView.inactiveTextColor = progressView.inactiveColor
//    progressView.stepFont = .semiBold(11)
//
//    let shouldHide: Bool
//    if viewModel.invitationStatus != nil {
//      progressView.titles = ["", "", "", "", ""]
//      progressView.stepTitles = ["1", "2", "3", "4", "✓"]
//      progressBarWidthConstraint.constant = 250
//    } else {
//      progressView.titles = ["", "", ""]
//      progressView.stepTitles = ["1", "2", "✓"]
//      progressBarWidthConstraint.constant = 130
//    }
//
//    shouldHide = viewModel.broadcastFailed
//    progressView.currentTab = viewModel.currentSelectedTab
//    progressView.isHidden = shouldHide
  }
}

extension TransactionHistoryDetailValidCell: TransactionHistoryDetailAddressViewDelegate {
  func addressViewDidSelectAddress(_ addressView: TransactionHistoryDetailCellAddressView) {
    self.delegate?.didTapAddress(detailCell: self)
  }
}
