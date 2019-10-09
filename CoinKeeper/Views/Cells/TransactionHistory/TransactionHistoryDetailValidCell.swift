//
//  TransactionHistoryDetailValidCell.swift
//  DropBit
//
//  Created by BJ Miller on 4/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import JKSteppedProgressBar

class TransactionHistoryDetailValidCell: TransactionHistoryDetailBaseCell {

  @IBOutlet var progressBarWidthConstraint: NSLayoutConstraint!
  @IBOutlet var progressView: SteppedProgressBar!
  @IBOutlet var addressView: TransactionHistoryDetailCellAddressView!
  @IBOutlet var bottomButton: TransactionDetailBottomButton!
  @IBOutlet var messageContainer: TransactionDetailsInfoContainer!
  @IBOutlet var messageLabel: TransactionDetailMessageLabel!
  @IBOutlet var messageContainerHeightConstraint: NSLayoutConstraint!
  @IBOutlet var bottomBufferView: UIView!

  override func awakeFromNib() {
    super.awakeFromNib()

    progressView.activeColor = .successGreen
    progressView.inactiveColor = .lightGrayText
    progressView.inactiveTextColor = progressView.inactiveColor
    progressView.stepFont = .semiBold(11)
  }

  override func configure(with values: TransactionDetailCellDisplayable, delegate: TransactionHistoryDetailCellDelegate) {
    super.configure(with: values, delegate: delegate)
    questionMarkButton.tag = values.tooltipType.buttonTag

    messageLabel.text = values.messageText
    messageContainer.isHidden = values.shouldHideMessageLabel
    messageLabel.isHidden = values.shouldHideMessageLabel

    layoutIfNeeded()
    messageContainerHeightConstraint.constant = messageLabel.intrinsicContentSize.height + 20

    progressView.isHidden = values.shouldHideProgressView
    if let config = values.progressConfig {
      progressView.titles = config.titles
      progressView.stepTitles = config.stepTitles
      progressView.currentTab = config.selectedTab
      progressBarWidthConstraint.constant = config.width
    }

    addressView.isHidden = values.shouldHideAddressView
    addressView.selectionDelegate = self
    addressView.configure(with: values.addressViewConfig)

    bottomButton.isHidden = values.shouldHideBottomButton
    if let config = values.actionButtonConfig {
      bottomButton.setAttributedTitle(nil, for: .normal)
      bottomButton.setTitle(config.title, for: .normal)
      bottomButton.backgroundColor = config.backgroundColor
      bottomButton.tag = config.buttonTag
    }

    bottomBufferView.isHidden = (UIScreen.main.relativeSize != .tall)
    layoutIfNeeded()
  }

  @IBAction func didTapBottomButton(_ sender: UIButton) {
    guard let action = TransactionDetailAction(rawValue: sender.tag) else { return }
    delegate?.didTapBottomButton(detailCell: self, action: action)
  }

}

extension TransactionHistoryDetailValidCell: TransactionHistoryDetailAddressViewDelegate {
  func addressViewDidSelectAddress(_ addressView: TransactionHistoryDetailCellAddressView) {
    self.delegate?.didTapAddressLinkButton(detailCell: self)
  }
}
