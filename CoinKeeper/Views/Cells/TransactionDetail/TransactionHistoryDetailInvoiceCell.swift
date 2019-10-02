//
//  TransactionHistoryDetailInvoiceCell.swift
//  DropBit
//
//  Created by Ben Winters on 10/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionHistoryDetailInvoiceCell: CollectionViewCardCell {

  weak var delegate: TransactionHistoryDetailCellDelegate!

  @IBOutlet var questionMarkButton: UIButton!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var expirationLabel: ExpirationLabel!

  @IBOutlet var invoiceAmountContainer: UIView!
  @IBOutlet var primaryAmountLabel: UILabel!
  @IBOutlet var secondaryAmountLabel: UILabel!

  @IBOutlet var qrHistoricalContainer: UIView!
  @IBOutlet var qrCodeImageView: UIImageView!
  @IBOutlet var historicalValuesLabel: UILabel!

  @IBOutlet var memoLabel: UILabel!

  @IBOutlet var copyInvoiceView: UIView!
  @IBOutlet var copyInvoiceLabel: UILabel!

  @IBOutlet var bottomButton: TransactionDetailBottomButton!
  @IBOutlet var dateLabel: TransactionDetailDateLabel!

  @IBAction func copyInvoice(_ sender: UIButton) {
    delegate.didTapInvoice(detailCell: self)
  }

  @IBAction func didTapClose(_ sender: UIButton) {
    delegate.didTapClose(detailCell: self)
  }

  @IBAction func didTapBottomButton(_ sender: UIButton) {
    guard let action = TransactionDetailAction(rawValue: sender.tag) else { return }
    delegate.didTapBottomButton(detailCell: self, action: action)
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    titleLabel.textColor = .darkBlueText
    titleLabel.font = .regular(14)

    primaryAmountLabel.textColor = .darkBlueText
    primaryAmountLabel.font = smallPrimaryAmountFont
    secondaryAmountLabel.textColor = .bitcoinOrange
    secondaryAmountLabel.font = .medium(14)

    memoLabel.textColor = .darkBlueText
    memoLabel.font = .regular(14)

    copyInvoiceView.applyCornerRadius(4)
    copyInvoiceView.layer.borderWidth = 2
    copyInvoiceView.layer.borderColor = UIColor.mediumGrayBorder.cgColor
    copyInvoiceView.backgroundColor = .clear

    copyInvoiceLabel.textColor = .darkBlueText
    copyInvoiceLabel.font = .medium(13)
  }

  func configure(with values: TransactionDetailInvoiceCellDisplayable, delegate: TransactionHistoryDetailCellDelegate) {
    self.delegate = delegate

    questionMarkButton.tag = values.tooltipType.buttonTag
    expirationLabel.configure(hoursRemaining: values.hoursUntilExpiration)

    primaryAmountLabel.text = values.detailAmountLabels.primaryText
    secondaryAmountLabel.attributedText = values.detailAmountLabels.secondaryAttributedText

    historicalValuesLabel.attributedText = values.detailAmountLabels.historicalPriceAttributedText
    qrCodeImageView.image = values.qrCodeImage
    qrHistoricalContainer.isHidden = values.shouldHideQRHistoricalContainer

    memoLabel.text = values.memo
    memoLabel.isHidden = values.shouldHideMemoLabel

    copyInvoiceLabel.text = values.encodedInvoice

    bottomButton.backgroundColor = values.actionButtonConfig.backgroundColor
    bottomButton.tag = values.actionButtonConfig.buttonTag
    bottomButton.setTitle(values.actionButtonConfig.title, for: .normal)

    dateLabel.text = values.displayDate
  }

  private var smallPrimaryAmountFont: UIFont {
    return .regular(30)
  }

  private var largePrimaryAmountFont: UIFont {
    return .regular(50)
  }

}
