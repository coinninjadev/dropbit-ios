//
//  TransactionHistoryDetailBaseCell.swift
//  DropBit
//
//  Created by BJ Miller on 4/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PromiseKit

enum DetailCellTooltip: Int {
  case dropBit = 1
  case regularOnChain

  var buttonTag: Int {
    return rawValue
  }
}

class CollectionViewCardCell: UICollectionViewCell {

  @IBOutlet var underlyingContentView: UIView!

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = UIColor.white
    layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    applyCornerRadius(13)

    // Shadow
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.5
    layer.shadowRadius = 2
    layer.shadowOffset = CGSize(width: 0, height: 4)
    self.clipsToBounds = false
    layer.masksToBounds = false

    underlyingContentView.backgroundColor = UIColor.white
    underlyingContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    underlyingContentView.applyCornerRadius(13)
  }
}

protocol TransactionHistoryDetailCellDelegate: class {
  func didTapQuestionMarkButton(detailCell: TransactionHistoryDetailBaseCell, tooltip: DetailCellTooltip)
  func didTapClose(detailCell: UICollectionViewCell)
  func didTapTwitterShare(detailCell: TransactionHistoryDetailBaseCell)
  func didTapAddressLinkButton(detailCell: TransactionHistoryDetailBaseCell)
  func didTapCopyInvoiceButton(detailCell: TransactionHistoryDetailInvoiceCell)
  func didTapBottomButton(detailCell: UICollectionViewCell, action: TransactionDetailAction)
  func didTapAddMemoButton(detailCell: TransactionHistoryDetailBaseCell)
}

class TransactionHistoryDetailBaseCell: CollectionViewCardCell {

  // MARK: outlets
  @IBOutlet var twitterShareButton: PrimaryActionButton? //may be nil for some xibs
  @IBOutlet var questionMarkButton: UIButton!
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var directionView: TransactionDirectionView!
  @IBOutlet var statusLabel: TransactionDetailStatusLabel!
  @IBOutlet var twitterAvatarView: TwitterAvatarView!
  @IBOutlet var counterpartyLabel: TransactionDetailCounterpartyLabel!
  @IBOutlet var primaryAmountLabel: TransactionDetailPrimaryAmountLabel!
  @IBOutlet var secondaryAmountLabel: TransactionDetailSecondaryAmountLabel!
  @IBOutlet var historicalValuesLabel: UILabel! //use attributedText
  @IBOutlet var addMemoButton: UIButton!
  @IBOutlet var memoContainerView: ConfirmPaymentMemoView!
  @IBOutlet var dateLabel: TransactionDetailDateLabel!

  weak var delegate: TransactionHistoryDetailCellDelegate?

  // MARK: object lifecycle
  override func awakeFromNib() {
    super.awakeFromNib()

    addMemoButton.styleAddButtonWith(title: "Add Memo")
    configureTwitterShareButton()
  }

  // MARK: actions
  @IBAction func didTapAddMemoButton(_ sender: UIButton) {
    delegate?.didTapAddMemoButton(detailCell: self)
  }

  @IBAction func didTapQuestionMarkButton(_ sender: UIButton) {
    guard let tooltipType = DetailCellTooltip(rawValue: sender.tag) else { return }
    delegate?.didTapQuestionMarkButton(detailCell: self, tooltip: tooltipType)
  }

  @IBAction func didTapTwitterShare(_ sender: UIButton) {
    delegate?.didTapTwitterShare(detailCell: self)
  }

  @IBAction func didTapClose(_ sender: UIButton) {
    delegate?.didTapClose(detailCell: self)
  }

  func configure(with values: TransactionDetailCellDisplayable, delegate: TransactionHistoryDetailCellDelegate) {
    self.delegate = delegate

    self.questionMarkButton.tag = values.tooltipType.rawValue
    self.twitterShareButton?.isHidden = values.shouldHideTwitterShareButton

    self.directionView.configure(image: values.directionConfig.image, bgColor: values.directionConfig.bgColor)
    self.statusLabel.text = values.detailStatusText
    self.statusLabel.textColor = values.detailStatusColor
    self.twitterAvatarView.isHidden = values.shouldHideAvatarView
    if let avatar = values.twitterConfig?.avatar {
      self.twitterAvatarView.configure(with: avatar, logoBackgroundColor: values.cellBackgroundColor)
    }

    self.counterpartyLabel.isHidden = values.shouldHideCounterpartyLabel
    self.counterpartyLabel.text = values.counterpartyText

    self.primaryAmountLabel.text = values.detailAmountLabels.primaryText
    self.secondaryAmountLabel.attributedText = values.detailAmountLabels.secondaryAttributedText
    self.historicalValuesLabel.isHidden = values.shouldHideHistoricalValuesLabel
    self.historicalValuesLabel.text = nil
    self.historicalValuesLabel.attributedText = values.detailAmountLabels.historicalPriceAttributedText

    self.memoContainerView.isHidden = values.shouldHideMemoView
    if let config = values.memoConfig {
      self.memoContainerView.configure(with: config)
    }

    self.addMemoButton.isHidden = values.shouldHideAddMemoButton

    self.dateLabel.text = values.displayDate
  }

  private func configureTwitterShareButton() {
    twitterShareButton?.configure(
      withTitle: "SHARE",
      font: .medium(10),
      foregroundColor: .lightGrayText,
      imageName: "twitterBird",
      imageSize: CGSize(width: 10, height: 10),
      titleEdgeInsets: UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2),
      contentEdgeInsets: UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 4)
    )
  }

}
