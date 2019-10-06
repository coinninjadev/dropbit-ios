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
  @IBOutlet var directionView: TransactionDirectionView!
  @IBOutlet var statusLabel: TransactionDetailBreakdownLabel!
  @IBOutlet var breakdownStackView: UIStackView!
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

    let breakdownStyle = TitleDetailViewStyleConfig(font: .regular(13), color: .darkGrayText)
    for item in viewModel.breakdownItems {
      let labelView = TitleDetailView(title: item.title, detail: item.detail, style: breakdownStyle)
      breakdownStackView.addArrangedSubview(labelView)
    }
    statusLabel.text = viewModel.detailStatusText
    txidLabel.text = viewModel.txid
    directionView.configure(image: viewModel.directionConfig.image, bgColor: viewModel.directionConfig.bgColor)
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
    seeTransactionDetailsButton.setTitle("VIEW ON BLOCK EXPLORER", for: .normal)
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
