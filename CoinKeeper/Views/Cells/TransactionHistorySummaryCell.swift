//
//  TransactionHistorySummaryCell.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistorySummaryCell: UICollectionViewCell {

  @IBOutlet var leadingImage: UIImageView!
  @IBOutlet var twitterImage: UIImageView!
  @IBOutlet var receiverLabel: TransactionHistoryReceiverLabel!
  @IBOutlet var statusLabel: TransactionHistoryDetailLabel!
  @IBOutlet var dateLabel: TransactionHistoryDetailLabel!
  @IBOutlet var memoLabel: TransactionHistoryMemoLabel!
  @IBOutlet var amountStackView: UIStackView!

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .white

    let radius = leadingDirectionBackgroundView.frame.width/2
    leadingDirectionBackgroundView.applyCornerRadius(radius)
    leadingDirectionImage.contentMode = .center

  }

  override func prepareForReuse() {
    super.prepareForReuse()

    twitterAvatarView.isHidden = true
    leadingDirectionBackgroundView.isHidden = true
    leadingDirectionImage.isHidden = true
  }

  // part of auto-sizing
  override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    let height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    layoutAttributes.bounds.size.height = height
    return layoutAttributes
  }

  func configure(with values: TransactionSummaryCellDisplayable, isAtTop: Bool = false) {
    configureLeadingViews(with: values.leadingImageConfig)
  }

  private func configureLeadingViews(with leadingConfig: SummaryCellLeadingImageConfig) {
    if let directionConfig = leadingConfig.directionConfig {
      self.leadingDirectionImage.image = directionConfig.image
      self.leadingDirectionBackgroundView.backgroundColor = directionConfig.bgColor
    }
  }

  /*
  func load(with viewModel: OldTransactionSummaryCellViewModel, isAtTop: Bool = false) {
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

    layer.maskedCorners = isAtTop ? [.layerMinXMinYCorner, .layerMaxXMinYCorner] : []
  }
  */

}
