//
//  TransactionHistoryDetailBaseCell.swift
//  DropBit
//
//  Created by BJ Miller on 4/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PromiseKit

protocol TransactionHistoryDetailCellDelegate: class {
  func didTapQuestionMarkButton(detailCell: TransactionHistoryDetailBaseCell, with url: URL)
  func didTapClose(detailCell: TransactionHistoryDetailBaseCell)
  func didTapTwitterShare(detailCell: TransactionHistoryDetailBaseCell)
  func didTapAddress(detailCell: TransactionHistoryDetailBaseCell)
  func didTapBottomButton(detailCell: TransactionHistoryDetailBaseCell)
  func didTapAddMemoButton(detailCell: TransactionHistoryDetailBaseCell)
//  func shouldSaveMemo(for transaction: CKMTransaction) -> Promise<Void>
}

class TransactionHistoryDetailBaseCell: UICollectionViewCell {

  // MARK: outlets
  @IBOutlet var underlyingContentView: UIView! {
    didSet {
      underlyingContentView.backgroundColor = UIColor.white
      underlyingContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
      underlyingContentView.applyCornerRadius(13)
    }
  }
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var questionMarkButton: UIButton!
  @IBOutlet var directionView: TransactionDirectionView!
  @IBOutlet var dateLabel: TransactionDetailDateLabel!
  @IBOutlet var primaryAmountLabel: TransactionDetailPrimaryAmountLabel!
  @IBOutlet var secondaryAmountLabel: TransactionDetailSecondaryAmountLabel!
  @IBOutlet var historicalValuesLabel: UILabel! //use attributedText
  @IBOutlet var addMemoButton: UIButton! {
    didSet {
      addMemoButton.styleAddButtonWith(title: "Add Memo")
    }
  }
  @IBOutlet var memoContainerView: ConfirmPaymentMemoView!
  @IBOutlet var statusLabel: TransactionDetailStatusLabel!
  @IBOutlet var counterpartyLabel: TransactionDetailCounterpartyLabel!
  @IBOutlet var twitterImage: UIImageView!
  @IBOutlet var twitterShareButton: PrimaryActionButton!

  // MARK: variables
  var viewModel: OldTransactionDetailCellViewModel?
  weak var delegate: TransactionHistoryDetailCellDelegate?

  // MARK: object lifecycle
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
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    viewModel = nil
  }

  // MARK: actions
  @IBAction func didTapAddMemoButton(_ sender: UIButton) {
    delegate?.didTapAddMemoButton(detailCell: self)
  }

  @IBAction func didTapQuestionMarkButton(_ sender: UIButton) {
    guard let url: URL = viewModel?.invitationStatus != nil ?
      CoinNinjaUrlFactory.buildUrl(for: .dropbitTransactionTooltip) : CoinNinjaUrlFactory.buildUrl(for: .regularTransactionTooltip) else { return }

    delegate?.didTapQuestionMarkButton(detailCell: self, with: url)
  }

  @IBAction func didTapTwitterShare(_ sender: Any) {
    delegate?.didTapTwitterShare(detailCell: self)
  }

  @IBAction func didTapClose(_ sender: Any) {
    delegate?.didTapClose(detailCell: self)
  }

  func configure(with values: TransactionSummaryCellDisplayable, delegate: TransactionHistoryDetailCellDelegate) {
    self.delegate = delegate

  }
//  func configure(with viewModel: OldTransactionDetailCellViewModel, delegate: TransactionHistoryDetailCellDelegate) {
//    self.delegate = delegate
//    self.viewModel = viewModel
//
//    configureTwitterShareButton()
//    incomingImage.image = viewModel.imageForTransactionDirection
//    dateLabel.text = viewModel.dateDescriptionFull
//    statusLabel.text = viewModel.statusDescription
//    statusLabel.textColor = viewModel.descriptionColor
//    let isEqualToReceiverAddress = (viewModel.receiverAddress ?? "") == viewModel.counterpartyDescription
//    counterpartyLabel.text = isEqualToReceiverAddress ? nil : viewModel.counterpartyDescription
//    twitterImage.isHidden = !viewModel.isTwitterContact
//    primaryAmountLabel.text = viewModel.primaryAmountLabel
//    secondaryAmountLabel.attributedText = viewModel.secondaryAmountLabel
//    historicalValuesLabel.text = nil
//    historicalValuesLabel.attributedText = viewModel.historicalAmountsAttributedString()
//    addMemoButton.isHidden = !viewModel.memo.isEmpty
//    memoContainerView.isHidden = viewModel.memo.isEmpty
//    memoContainerView.configure(
//      memo: viewModel.memo,
//      isShared: viewModel.memoWasShared,
//      isSent: true,
//      isIncoming: viewModel.isIncoming,
//      recipientName: nil)
//  }

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
