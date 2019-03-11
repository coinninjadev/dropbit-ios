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
    layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    return layoutAttributes
  }

  func load(with cellData: TransactionHistorySummaryCellViewModel) {
    if cellData.transactionIsInvalidated {
      incomingImage.image = UIImage(named: "invalidated30")
    } else {
      incomingImage.image = cellData.isIncoming ? UIImage(named: "incoming30") : UIImage(named: "outgoing30")
    }

    receiverLabel.text = cellData.counterpartyDescription.isEmpty ? cellData.receiverAddress : cellData.counterpartyDescription
    statusLabel.text = cellData.statusDescription
    statusLabel.isHidden = cellData.hidden

    statusLabel.textColor = cellData.descriptionColor

    dateLabel.text = cellData.dateDescriptionFull

    // fall back to sent amount if still pending and fees are not known
    let converter = cellData.receivedAmountAtCurrentConverter ?? cellData.sentAmountAtCurrentConverter
    let labels = cellData.amountLabels(for: converter)

    primaryAmountLabel.text = labels.primary
    secondaryAmountLabel.text = labels.secondary
    primaryAmountLabel.textColor = cellData.isIncoming ? Theme.Color.darkBlueText.color : Theme.Color.errorRed.color

    memoLabel.text = cellData.memo
    memoLabel.isHidden = cellData.memo.isEmpty
  }

}
