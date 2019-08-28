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
    amountStackView.distribution = .equalCentering
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    twitterAvatarView.isHidden = true
    directionView.isHidden = true
    amountStackView.arrangedSubviews.forEach { subview in
      amountStackView.removeArrangedSubview(subview)
      subview.removeFromSuperview()
    }
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
    configureAmountLabels(with: values.summaryAmountLabels,
                          accentColor: values.accentColor,
                          walletTxType: values.walletTxType,
                          selectedCurrency: values.selectedCurrency)
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

  private func configureAmountLabels(with labels: SummaryCellAmountLabels,
                                     accentColor: UIColor,
                                     walletTxType: WalletTransactionType,
                                     selectedCurrency: SelectedCurrency) {
    let pillLabel = SummaryCellPillLabel(frame: CGRect(x: 0, y: 0, width: 0, height: 28))
    pillLabel.configure(withText: labels.pillText, backgroundColor: accentColor, isAmount: labels.pillIsAmount)
    pillLabel.setNeedsLayout()
    pillLabel.setNeedsUpdateConstraints()
    let textLabel = btcLabel(for: labels, walletTxType: walletTxType)

    switch selectedCurrency {
    case .fiat:
      amountStackView.addArrangedSubview(pillLabel)
      amountStackView.addArrangedSubview(textLabel)
    case .BTC:
      amountStackView.addArrangedSubview(textLabel)
      amountStackView.addArrangedSubview(pillLabel)
    }
  }

  private func btcLabel(for labels: SummaryCellAmountLabels, walletTxType: WalletTransactionType) -> UILabel {
    switch walletTxType {
    case .onChain:
      let bitcoinLabel = SummaryCellBitcoinLabel(frame: .zero)
      bitcoinLabel.attributedText = labels.btcAttributedText
      return bitcoinLabel
    case .lightning:
      let satsLabel = SummaryCellSatsLabel(frame: .zero)
      satsLabel.text = labels.satsText
      return satsLabel
    }
  }

}
