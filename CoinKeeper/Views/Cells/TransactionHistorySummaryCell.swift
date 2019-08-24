//
//  TransactionHistorySummaryCell.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistorySummaryCell: UICollectionViewCell {

  @IBOutlet var directionView: TransactionDirectionView!
  @IBOutlet var twitterAvatarView: TwitterAvatarView!
  @IBOutlet var counterpartyLabel: TransactionHistoryCounterpartyLabel!
  @IBOutlet var memoLabel: SummaryCellMemoLabel!
  @IBOutlet var amountStackView: UIStackView!

  override func awakeFromNib() {
    super.awakeFromNib()

    layer.cornerRadius = 13.0
    amountStackView.alignment = .trailing
    amountStackView.distribution = .equalSpacing
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    twitterAvatarView.isHidden = true
    directionView.isHidden = true
  }

  // part of auto-sizing
  override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    let height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    layoutAttributes.bounds.size.height = height
    return layoutAttributes
  }

  func configure(with values: TransactionSummaryCellDisplayable, isAtTop: Bool = false) {
    self.backgroundColor = values.cellBackgroundColor

    if isAtTop {
      layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    } else {
      layer.maskedCorners = []
    }

    configureIsHidden(with: values)
    configureLeadingViews(with: values.leadingImageConfig, cellBgColor: values.cellBackgroundColor)
    counterpartyLabel.text = values.counterpartyText
    memoLabel.text = values.memo
  }

  /// Configures isHidden for all subviews of this cell where that property varies
  private func configureIsHidden(with values: TransactionSummaryCellDisplayable) {
    directionView.isHidden = values.directionViewIsHidden
    twitterAvatarView.isHidden = values.avatarViewIsHidden
    memoLabel.isHidden = values.memoLabelIsHidden
  }

  private func configureLeadingViews(with leadingConfig: SummaryCellLeadingImageConfig, cellBgColor: UIColor) {
    if let directionConfig = leadingConfig.directionConfig {
      self.directionView.configure(image: directionConfig.image, bgColor: directionConfig.bgColor)
    }

    if let avatarConfig = leadingConfig.avatarConfig {
      self.twitterAvatarView.configure(with: avatarConfig.image, logoBackgroundColor: cellBgColor)
    }
  }

}
