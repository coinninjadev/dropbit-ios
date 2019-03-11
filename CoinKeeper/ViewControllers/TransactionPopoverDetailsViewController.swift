//
//  TransactionPopoverDetailsViewController.swift
//  DropBit
//
//  Created by Mitch on 12/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol TransactionPopoverDetailsViewControllerDelegate: ViewControllerDismissable {
  func viewControllerDidTapTransactionDetailsButton(with url: URL)
  func viewControllerDidTapQuestionMarkButton(with url: URL)
  func viewControllerDidTapShareTransactionButton()
}

class TransactionPopoverDetailsViewController: BaseViewController, StoryboardInitializable, PopoverViewControllerType {

  @IBOutlet var containerView: UIView!
  @IBOutlet var transactionDirectionImageView: UIImageView!
  @IBOutlet var statusLabel: TransactionDetailBreakdownLabel!
  @IBOutlet var whenSentTitleLabel: TransactionDetailBreakdownLabel!
  @IBOutlet var whenSentAmountLabel: TransactionDetailBreakdownLabel!
  @IBOutlet var networkFeeTitleLabel: TransactionDetailBreakdownLabel!
  @IBOutlet var networkFeeAmountLabel: TransactionDetailBreakdownLabel!
  @IBOutlet var confirmationsTitleLabel: TransactionDetailBreakdownLabel!
  @IBOutlet var confirmationsAmountLabel: TransactionDetailBreakdownLabel!
  @IBOutlet var txidLabel: UILabel!
  @IBOutlet var seeTransactionDetailsButton: TransactionDetailBottomButton!
  @IBOutlet var shareTransactionButton: UIButton!
  @IBOutlet var questionMarkButton: UIButton!
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var containerViewCenterYConstraint: NSLayoutConstraint!

  private let height: CGFloat = 410

  var viewModel: TransactionHistoryDetailCellViewModel?

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  var coordinationDelegate: TransactionPopoverDetailsViewControllerDelegate? {
    return generalCoordinationDelegate as? TransactionPopoverDetailsViewControllerDelegate
  }

  private func setupUI() {
    view.isOpaque = false
    view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.85)
    txidLabel.font = Theme.Font.shareTransactionTitle.font
    txidLabel.textColor = Theme.Color.darkBlueText.color
    shareTransactionButton.setTitleColor(Theme.Color.lightBlueTint.color, for: .normal)
    shareTransactionButton.titleLabel?.font = Theme.Font.shareTransactionTitle.font
    containerView.layer.cornerRadius = 15
    containerView.clipsToBounds = true
    setupViewWithModel()
    addDismissibleTapToBackground()
  }

  private func setupViewWithModel() {
    guard let viewModel = viewModel else { return }

    whenSentAmountLabel.text = viewModel.breakdownSentAmountLabel
    networkFeeAmountLabel.text = viewModel.breakdownFeeAmountLabel
    confirmationsAmountLabel.text = viewModel.confirmations >= 6 ? "6+" :
      String(describing: viewModel.confirmations)
    statusLabel.text = viewModel.statusDescription
    txidLabel.text = viewModel.transaction?.txid
    transactionDirectionImageView.image = viewModel.imageForTransactionDirection
  }

  func dismissPopoverViewController() {
    containerViewCenterYConstraint.constant = (UIScreen.main.bounds.height / 2) + (height / 2)

    UIView.setAnimationCurve(.easeOut)
    UIView.animate(withDuration: 0.3, animations: { [weak self] in
      self?.view.layoutIfNeeded()
      }, completion: { [weak self] _ in
        guard let strongSelf = self else { return }
        strongSelf.coordinationDelegate?.viewControllerDidSelectClose(strongSelf)
    })
  }

  @IBAction func viewControllerDidTapTransactionDetailsButton() {
    guard let txid = viewModel?.transaction?.txid, let url = CoinNinjaUrlFactory.buildUrl(for: .transaction(id: txid)) else { return }
    coordinationDelegate?.viewControllerDidTapTransactionDetailsButton(with: url)
  }

  @IBAction func viewControllerDidTapShareTransactionButton() {
    coordinationDelegate?.viewControllerDidTapShareTransactionButton()
    guard let transaction = viewModel?.transaction, transaction.txidIsActualTxid,
      let url = CoinNinjaUrlFactory.buildUrl(for: .transaction(id: transaction.txid)) else { return }

    let activityViewController = UIActivityViewController(activityItems: [url.absoluteString], applicationActivities: nil)
    present(activityViewController, animated: true, completion: nil)
  }

  @IBAction func closeButtonTapped() {
    dismissPopoverViewController()
  }

  @IBAction func viewControllerDidTapQuestionMarkButton() {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .detailsTooltip) else { return }
    coordinationDelegate?.viewControllerDidTapQuestionMarkButton(with: url)
  }
}
