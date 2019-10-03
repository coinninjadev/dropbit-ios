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

  @IBOutlet var centerStackView: UIStackView!

  @IBOutlet var invoiceAmountContainer: UIView!
  @IBOutlet var primaryAmountLabel: UILabel!
  @IBOutlet var secondaryAmountLabel: UILabel!

  @IBOutlet var qrHistoricalContainer: UIView!
  @IBOutlet var qrCodeImageView: UIImageView!
  @IBOutlet var qrCodeImageWidthConstraint: NSLayoutConstraint!
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
    primaryAmountLabel.font = .regular(50)
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

    let layoutConfig = sizeRelativeLayoutConfig(qrIsShown: !values.shouldHideQRHistoricalContainer)
    centerStackView.spacing = layoutConfig.stackSpacing

    questionMarkButton.tag = values.tooltipType.buttonTag
    expirationLabel.configure(hoursRemaining: values.hoursUntilExpiration)

    primaryAmountLabel.text = values.detailAmountLabels.primaryText
    secondaryAmountLabel.attributedText = values.detailAmountLabels.secondaryAttributedText
    primaryAmountLabel.font = .regular(layoutConfig.primaryAmountFontSize)

    historicalValuesLabel.attributedText = values.detailAmountLabels.historicalPriceAttributedText
    historicalValuesLabel.isHidden = true //TODO: populate and show this when historical exchange rates are available for invoices

    qrCodeImageWidthConstraint.constant = layoutConfig.qrCodeWidth
    qrCodeImageView.image = values.qrImage(withSize: layoutConfig.qrCodeSize)
    qrHistoricalContainer.isHidden = values.shouldHideQRHistoricalContainer

    memoLabel.text = values.memo
    memoLabel.isHidden = values.shouldHideMemoLabel

    copyInvoiceLabel.text = values.lightningInvoice

    let actionConfig = values.invoiceActionConfig
    bottomButton.backgroundColor = actionConfig.backgroundColor
    bottomButton.tag = actionConfig.buttonTag
    bottomButton.setTitle(actionConfig.title, for: .normal)

    dateLabel.text = values.displayDate
  }

  private func sizeRelativeLayoutConfig(qrIsShown: Bool) -> InvoiceCellLayoutConfig {
    let qrSensitiveFontSize: CGFloat = qrIsShown ? 30 : 50
    switch UIScreen.main.relativeSize {
    case .short:  return InvoiceCellLayoutConfig(stackSpacing: 8, primaryAmountFontSize: 30, qrCodeWidth: 140)
    case .medium: return InvoiceCellLayoutConfig(stackSpacing: 16, primaryAmountFontSize: qrSensitiveFontSize, qrCodeWidth: 160)
    case .tall:   return InvoiceCellLayoutConfig(stackSpacing: 32, primaryAmountFontSize: 50, qrCodeWidth: 200)
    }
  }

}

struct InvoiceCellLayoutConfig {
  let stackSpacing: CGFloat
  let primaryAmountFontSize: CGFloat
  let qrCodeWidth: CGFloat

  var qrCodeSize: CGSize {
    return CGSize(width: qrCodeWidth, height: qrCodeWidth)
  }
}
