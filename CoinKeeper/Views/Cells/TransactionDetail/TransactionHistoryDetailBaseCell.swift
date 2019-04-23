//
//  TransactionHistoryDetailBaseCell.swift
//  DropBit
//
//  Created by BJ Miller on 4/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PromiseKit
import os.log

protocol TransactionHistoryDetailCellDelegate: class {
  func didTapQuestionMarkButton(detailCell: TransactionHistoryDetailBaseCell, with url: URL)
  func didTapClose(detailCell: TransactionHistoryDetailBaseCell)
  func didTapAddress(detailCell: TransactionHistoryDetailCell)
  func didTapBottomButton(detailCell: TransactionHistoryDetailCell, action: TransactionDetailAction)
  func didTapAddMemoButton(completion: @escaping (String) -> Void)
  func shouldSaveMemo(for transaction: CKMTransaction) -> Promise<Void>
}

class TransactionHistoryDetailBaseCell: UICollectionViewCell {

  // MARK: outlets
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var questionMarkButton: UIButton!
  @IBOutlet var incomingImage: UIImageView!
  @IBOutlet var dateLabel: TransactionDetailDateLabel!
  @IBOutlet var primaryAmountLabel: TransactionDetailPrimaryAmountLabel!
  @IBOutlet var secondaryAmountLabel: TransactionDetailSecondaryAmountLabel!
  @IBOutlet var historicalValuesLabel: UILabel! //use attributedText
  @IBOutlet var addMemoButton: UIButton! {
    didSet {
      addMemoButton.setTitleColor(Theme.Color.grayText.color, for: .normal)
      addMemoButton.titleLabel?.font = Theme.Font.addMemoTitle.font
    }
  }
  @IBOutlet var memoContainerView: ConfirmPaymentMemoView!
  @IBOutlet var statusLabel: TransactionDetailStatusLabel!
  @IBOutlet var counterpartyLabel: TransactionDetailCounterpartyLabel!

  // MARK: variables
  var viewModel: TransactionHistoryDetailCellViewModel?
  weak var delegate: TransactionHistoryDetailCellDelegate?

  // MARK: object lifecycle
  override func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = UIColor.white
    layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    layer.cornerRadius = 13

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
    delegate?.didTapAddMemoButton { [weak self] memo in
      guard let vm = self?.viewModel, let delegate = self?.delegate, let tx = vm.transaction else { return }
      tx.memo = memo

      delegate.shouldSaveMemo(for: tx)
        .done {
          vm.memo = memo
          self?.load(with: vm, delegate: delegate)
        }.catch { error in
          let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "add_memo")
          os_log("failed to add memo: %@", log: logger, type: .error, error.localizedDescription)
      }
    }
  }

  @IBAction func didTapQuestionMarkButton(_ sender: UIButton) {
    guard let url: URL = viewModel?.invitationStatus != nil ?
      CoinNinjaUrlFactory.buildUrl(for: .dropbitTransactionTooltip) : CoinNinjaUrlFactory.buildUrl(for: .regularTransactionTooltip) else { return }

    delegate?.didTapQuestionMarkButton(detailCell: self, with: url)
  }

  @IBAction func didTapClose(_ sender: Any) {
    delegate?.didTapClose(detailCell: self)
  }

  func load(with viewModel: TransactionHistoryDetailCellViewModel, delegate: TransactionHistoryDetailCellDelegate) {
    self.delegate = delegate
    self.viewModel = viewModel

    // incomingImage
    incomingImage.image = viewModel.imageForTransactionDirection
    // dateLabel
    dateLabel.text = viewModel.dateDescriptionFull
    // statusLabel
    statusLabel.text = viewModel.statusDescription
    statusLabel.textColor = viewModel.descriptionColor
    // counterPartyLabel
    let isEqualToReceiverAddress = (viewModel.receiverAddress ?? "") == viewModel.counterpartyDescription
    counterpartyLabel.text = isEqualToReceiverAddress ? nil : viewModel.counterpartyDescription
    // primaryAmountLabel
    primaryAmountLabel.text = viewModel.primaryAmountLabel
    // secondaryAmountLabel
    secondaryAmountLabel.attributedText = viewModel.secondaryAmountLabel
    // historicalValuesLabel
    historicalValuesLabel.text = nil
    historicalValuesLabel.attributedText = viewModel.historicalAmountsAttributedString()
    // addMemoButton
    addMemoButton.isHidden = !viewModel.memo.isEmpty
    // memoContainerView
    memoContainerView.isHidden = viewModel.memo.isEmpty
    memoContainerView.configure(
      memo: viewModel.memo,
      isShared: viewModel.memoWasShared,
      isSent: true,
      isIncoming: viewModel.isIncoming,
      recipientName: nil)
  }


}
