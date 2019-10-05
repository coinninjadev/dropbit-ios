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

  private(set) weak var delegate: TransactionPopoverDetailsViewControllerDelegate!
  private var viewModel: TransactionDetailPopoverDisplayable?

  static func newInstance(delegate: TransactionPopoverDetailsViewControllerDelegate,
                          viewModel: TransactionDetailPopoverDisplayable) -> TransactionPopoverDetailsViewController {
    let vc = TransactionPopoverDetailsViewController.makeFromStoryboard()
    vc.delegate = delegate
    vc.viewModel = viewModel
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    configureWithViewModel()
  }

  private func configureWithViewModel() {
    guard let viewModel = viewModel else { return }

    whenSentAmountLabel.text = viewModel.breakdownSentAmountText
    networkFeeAmountLabel.text = viewModel.breakdownFeeAmountText
    confirmationsAmountLabel.text = viewModel.confirmationsText
    statusLabel.text = viewModel.detailStatusText
    txidLabel.text = viewModel.txid
    transactionDirectionImageView.image = nil // need to change view to use new one
  }

  private func setupUI() {
    view.isOpaque = false
    view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.85)
    txidLabel.font = .semiBold(14)
    txidLabel.textColor = .darkBlueText
    shareTransactionButton.setTitleColor(.lightBlueTint, for: .normal)
    shareTransactionButton.titleLabel?.font = .semiBold(14)
    containerView.applyCornerRadius(15)
    addDismissibleTapToBackground()
    let title = "VIEW ON BLOCK EXPLORER"
    seeTransactionDetailsButton.setTitle(title, for: .normal)
  }

  func dismissPopoverViewController() {
    containerViewCenterYConstraint.constant = (UIScreen.main.bounds.height / 2) + (height / 2)

    UIView.setAnimationCurve(.easeOut)
    UIView.animate(withDuration: 0.3, animations: { [weak self] in
      self?.view.layoutIfNeeded()
      }, completion: { [weak self] _ in
        guard let strongSelf = self else { return }
        strongSelf.delegate.viewControllerDidSelectClose(strongSelf)
    })
  }

  @IBAction func viewControllerDidTapTransactionDetailsButton() {
    guard let url = viewModel?.txidURL else { return }
    delegate.viewControllerDidTapTransactionDetailsButton(with: url)
  }

  @IBAction func viewControllerDidTapShareTransactionButton() {
    delegate.viewControllerDidTapShareTransactionButton()
    guard let url = viewModel?.txidURL else { return }

    let activityViewController = UIActivityViewController(activityItems: [url.absoluteString],
                                                          applicationActivities: nil)
    present(activityViewController, animated: true, completion: nil)
  }

  @IBAction func closeButtonTapped() {
    dismissPopoverViewController()
  }

  @IBAction func viewControllerDidTapQuestionMarkButton() {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .detailsTooltip) else { return }
    delegate.viewControllerDidTapQuestionMarkButton(with: url)
  }
}
