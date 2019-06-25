//
//  TransactionHistorySummaryCell.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistorySummaryCell: UICollectionViewCell {

  @IBOutlet var incomingImage: UIImageView!
  @IBOutlet var twitterImage: UIImageView!
  @IBOutlet var receiverLabel: TransactionHistoryReceiverLabel!
  @IBOutlet var statusLabel: TransactionHistoryDetailLabel!
  @IBOutlet var dateLabel: TransactionHistoryDetailLabel!
  @IBOutlet var memoLabel: TransactionHistoryMemoLabel!
  @IBOutlet var primaryAmountLabel: TransactionHistoryPrimaryAmountLabel!
  @IBOutlet var secondaryAmountLabel: TransactionHistorySecondaryAmountLabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundColor = UIColor.clear
  }

  // part of auto-sizing
  override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    let height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    layoutAttributes.bounds.size.height = height
    return layoutAttributes
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    incomingImage.layer.borderColor = nil
    incomingImage.layer.borderWidth = 0
    incomingImage.layer.cornerRadius = 0
  }

  func load(with viewModel: TransactionHistorySummaryCellViewModel) {
    if viewModel.isTwitterContact, let avatar = viewModel.counterpartyAvatar {
      incomingImage.image = avatar
      let radius = incomingImage.frame.width / 2.0
      incomingImage.applyCornerRadius(radius)
      let borderColor: UIColor = viewModel.isIncoming ? .appleGreen : .darkPeach
      incomingImage.layer.borderColor = borderColor.cgColor
      incomingImage.layer.borderWidth = 2.0
    } else {
      if viewModel.transactionIsInvalidated {
        incomingImage.image = UIImage(named: "invalidated30")
      } else {
        incomingImage.image = viewModel.isIncoming ? UIImage(named: "incoming30") : UIImage(named: "outgoing30")
      }
    }

    receiverLabel.text = viewModel.counterpartyDescription.isEmpty ? viewModel.receiverAddress : viewModel.counterpartyDescription
    twitterImage.isHidden = !viewModel.isTwitterContact
    statusLabel.text = viewModel.statusDescription
    statusLabel.isHidden = viewModel.hidden

    statusLabel.textColor = viewModel.descriptionColor

    dateLabel.text = viewModel.dateDescriptionFull

    // fall back to sent amount if still pending and fees are not known
    let converter = viewModel.receivedAmountAtCurrentConverter ?? viewModel.sentAmountAtCurrentConverter
    let labels = viewModel.amountLabels(for: converter)

    primaryAmountLabel.text = labels.primary
    secondaryAmountLabel.text = labels.secondary
    primaryAmountLabel.textColor = viewModel.isIncoming ? .darkBlueText : .darkPeach

    memoLabel.text = viewModel.memo
    memoLabel.isHidden = viewModel.memo.isEmpty
  }

}
