//
//  PrivateKeySweepViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import Cnlib

protocol PrivateKeySweepViewControllerDelegate: ViewControllerDismissable {
  func viewControllerDidConfirmTransfer(_ viewController: UIViewController, transactionData: CNBCnlibTransactionData)
}

class PrivateKeySweepViewController: BaseViewController, PopoverViewControllerType, StoryboardInitializable {
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var containerView: UIView!
  @IBOutlet var privateKeyLabelBackgroundView: UIView!
  @IBOutlet var privateKeyLabel: UILabel!
  @IBOutlet var actionButton: UIButton!
  @IBOutlet var cancelButton: UIButton!
  @IBOutlet var breakdownStackView: UIStackView!
  @IBOutlet var containerViewCenterYConstraint: NSLayoutConstraint!
  @IBOutlet var containerViewHeightConstraint: NSLayoutConstraint!

  weak var delegate: PrivateKeySweepViewControllerDelegate!

  private let height: CGFloat = 383
  private var breakdownItems: [TransactionBreakdownItem] = []
  private var totalBreakdownItem: TransactionBreakdownItem?
  private var privateKey: WIFPrivateKey!
  private var transactionData: CNBCnlibTransactionData?
  private var isPrivateKeyEmpty = false

  static func newInstance(emptyPrivateKey privateKey: WIFPrivateKey,
                          delegate: PrivateKeySweepViewControllerDelegate) -> PrivateKeySweepViewController {
    let viewController = PrivateKeySweepViewController.makeFromStoryboard()
    viewController.delegate = delegate
    viewController.privateKey = privateKey
    viewController.isPrivateKeyEmpty = true
    viewController.commonInit()
    return viewController
  }

  static func newInstance(delegate: PrivateKeySweepViewControllerDelegate,
                          privateKey: WIFPrivateKey,
                          transactionData: CNBCnlibTransactionData) -> PrivateKeySweepViewController {
    let viewController = PrivateKeySweepViewController.makeFromStoryboard()
    viewController.delegate = delegate
    viewController.privateKey = privateKey
    viewController.transactionData = transactionData
    let rates = ExchangeRateManager().exchangeRates

    let amount = NSDecimalNumber(integerAmount: transactionData.amount, currency: .BTC)
    let fee = NSDecimalNumber(integerAmount: transactionData.feeAmount, currency: .BTC)
    let total = amount + fee

    let amountConverter = CurrencyConverter(fromBtcTo: .USD, fromAmount: amount, rates: rates)
    let feeConverter = CurrencyConverter(fromBtcTo: .USD, fromAmount: fee, rates: rates)
    let totalConverter = CurrencyConverter(fromBtcTo: .USD, fromAmount: total, rates: rates)

    let amounts = ConvertedAmounts(converter: amountConverter)
    let feeAmounts = ConvertedAmounts(converter: feeConverter)
    let totalAmounts = ConvertedAmounts(converter: totalConverter)

    let totalItem = TransactionBreakdownItem(amount: BreakdownAmount(type: .total, amounts: totalAmounts, walletTxType: .onChain))
    viewController.totalBreakdownItem = totalItem

    let amountItem = TransactionBreakdownItem(amount: BreakdownAmount(type: .totalWithdrawal(.onChain),
                                                                      amounts: amounts, walletTxType: .onChain))
    let networkFees = TransactionBreakdownItem(amount: BreakdownAmount(type: .networkFees(paidByDropBit: false),
                                                                       amounts: feeAmounts, walletTxType: .onChain))
    viewController.breakdownItems = [amountItem, networkFees]
    viewController.commonInit()

    return viewController
  }

  private func commonInit() {
    modalPresentationStyle = .overFullScreen
    modalTransitionStyle = .crossDissolve
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if isPrivateKeyEmpty {
      actionButton.setTitle("OK", for: .normal)
      titleLabel.text = "This private key has no funds to transfer"
      titleLabel.textColor = .darkRed
      containerViewHeightConstraint.constant = 200
      cancelButton.isHidden = true
      breakdownStackView.isHidden = true
    } else {
      titleLabel.text = "Would you like to transfer the funds from this private key to your DropBit wallet?"
      breakdownStackView.distribution = .equalSpacing

      let breakdownStyle = TitleDetailViewStyleConfig(font: .regular(13), color: .darkGrayText)
      for item in breakdownItems {
        let labelView = TitleDetailView(title: item.title, detail: item.detail, style: breakdownStyle)
        breakdownStackView.addArrangedSubview(labelView)
      }

      if let item = totalBreakdownItem {
        let view = UIView()
        view.backgroundColor = .darkGray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 2).isActive = true
        breakdownStackView.addArrangedSubview(view)

        let totalBreakdownStyle = TitleDetailViewStyleConfig(font: .bold(13), color: .darkGrayText)
        let totalLabelView = TitleDetailView(title: item.title, detail: item.detail, style: totalBreakdownStyle)
        breakdownStackView.addArrangedSubview(totalLabelView)
      }
    }

    view.isOpaque = false
    view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.85)
    addDismissibleTapToBackground()
    containerView.applyCornerRadius(10)

    titleLabel.numberOfLines = 0

    privateKeyLabelBackgroundView.backgroundColor = .lightGrayBackground
    privateKeyLabelBackgroundView.applyCornerRadius(10)
    privateKeyLabel.text = privateKey.key.privateKeyAsWIF
    privateKeyLabel.lineBreakMode = .byTruncatingMiddle
    privateKeyLabel.backgroundColor = .clear
    privateKeyLabel.minimumScaleFactor = 0.50
    privateKeyLabel.baselineAdjustment = .alignCenters
  }

  @IBAction func actionButtonWasTouched() {
    if isPrivateKeyEmpty {
      delegate.viewControllerDidSelectClose(self)
    } else {
      guard let transactionData = transactionData else { return }
      delegate.viewControllerDidConfirmTransfer(self, transactionData: transactionData)
    }
  }

  @IBAction func cancelButtonWasTouched() {
    delegate.viewControllerDidSelectClose(self)
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
}
