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
  func didTapQuestionMark(detailCell: TransactionHistoryDetailBaseCell)
  func didTapClose(detailCell: TransactionHistoryDetailBaseCell)
  func didTapTwitterShare(detailCell: TransactionHistoryDetailBaseCell)
  func didTapAddress(detailCell: TransactionHistoryDetailBaseCell)
  func didTapBottomButton(detailCell: TransactionHistoryDetailBaseCell)
  func didTapAddMemo(detailCell: TransactionHistoryDetailBaseCell)
  func shouldSaveMemo(for transaction: CKMTransaction) -> Promise<Void>
}

//TODO: resolve commented out implementations
class TransactionHistoryDetailBaseCell: UICollectionViewCell {

  // MARK: outlets
  @IBOutlet var underlyingContentView: UIView!
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var questionMarkButton: UIButton!
  @IBOutlet var directionImageView: UIImageView!
  @IBOutlet var dateLabel: TransactionDetailDateLabel!
  @IBOutlet var primaryAmountLabel: TransactionDetailPrimaryAmountLabel!
  @IBOutlet var secondaryAmountLabel: TransactionDetailSecondaryAmountLabel!
  @IBOutlet var historicalValuesLabel: UILabel! //use attributedText
  @IBOutlet var addMemoButton: UIButton!
  @IBOutlet var memoContainerView: ConfirmPaymentMemoView!
  @IBOutlet var statusLabel: TransactionDetailStatusLabel!
  @IBOutlet var counterpartyLabel: TransactionDetailCounterpartyLabel!
  @IBOutlet var twitterImage: UIImageView!
  @IBOutlet var twitterShareButton: TwitterShareButton!

  // MARK: variables
  weak var delegate: TransactionHistoryDetailCellDelegate!

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

    underlyingContentView.backgroundColor = UIColor.white
    underlyingContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    underlyingContentView.applyCornerRadius(13)
    addMemoButton.styleAddButtonWith(title: "Add Memo")
  }

  // MARK: actions
  @IBAction func didTapAddMemoButton(_ sender: UIButton) {
    delegate.didTapAddMemo(detailCell: self)
  }

  @IBAction func didTapQuestionMark(_ sender: UIButton) {
    delegate.didTapQuestionMark(detailCell: self)
  }

  @IBAction func didTapTwitterShare(_ sender: Any) {
    delegate.didTapTwitterShare(detailCell: self)
  }

  @IBAction func didTapClose(_ sender: Any) {
    delegate.didTapClose(detailCell: self)
  }

  func load(with values: TransactionDetailCellDisplayable, delegate: TransactionHistoryDetailCellDelegate) {
    self.delegate = delegate

  }

}
