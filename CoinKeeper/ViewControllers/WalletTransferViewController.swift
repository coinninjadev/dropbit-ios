//
//  WalletTransferViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import SVProgressHUD
import CNBitcoinKit
import PromiseKit

enum TransferAmount {
  case low
  case medium
  case high
  case max
  case custom

  var value: Int {
    switch self {
    case .low: return 500
    case .medium: return 2000
    case .high: return 5000
    case .max: return 10000
    case .custom: return 0
    }
  }
}

protocol WalletTransferViewControllerDelegate: ViewControllerDismissable, PaymentBuildingDelegate, PaymentSendingDelegate {

  func viewControllerNeedsTransactionData(_ viewController: UIViewController,
                                          btcAmount: NSDecimalNumber,
                                          exchangeRates: ExchangeRates) -> PaymentData?

  func viewControllerDidConfirmLoad(_ viewController: UIViewController,
                                    paymentData: PaymentData)

  func viewControllerDidConfirmWithdraw(_ viewController: UIViewController, btcAmount: NSDecimalNumber)
}

enum TransferDirection {
  case toLightning(PaymentData?) //load
  case toOnChain(NSDecimalNumber?) //withdraw
}

class WalletTransferViewController: PresentableViewController, StoryboardInitializable, CurrencySwappableAmountEditor {

  var rateManager: ExchangeRateManager = ExchangeRateManager()

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var transferImageView: UIImageView!
  @IBOutlet var editAmountView: CurrencySwappableEditAmountView!
  @IBOutlet var confirmView: ConfirmView!
  @IBOutlet var feesView: FeesView!

  private(set) var viewModel: WalletTransferViewModel!

  static func newInstance(delegate: WalletTransferViewControllerDelegate, viewModel: WalletTransferViewModel) -> WalletTransferViewController {
    let viewController = WalletTransferViewController.makeFromStoryboard()
    viewController.viewModel = viewModel
    viewController.generalCoordinationDelegate = delegate
    return viewController
  }

  var editAmountViewModel: CurrencySwappableEditAmountViewModel {
    return viewModel
  }

  var currencyValueManager: CurrencyValueDataSourceType?

  var coordinationDelegate: WalletTransferViewControllerDelegate? {
    return generalCoordinationDelegate as? WalletTransferViewControllerDelegate
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    confirmView.delegate = self
    feesView.delegate = self
    let labels = viewModel.dualAmountLabels(walletTransactionType: viewModel.walletTransactionType)
    editAmountView.configure(withLabels: labels, delegate: self)
    currencyValueManager = generalCoordinationDelegate as? CurrencyValueDataSourceType
    setupUI()
    setupCurrencySwappableEditAmountView()
    buildTransactionIfNecessary()
  }

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    updateEditAmountView(withRates: exchangeRateManager.exchangeRates)
  }

  @IBAction func closeButtonWasTouched() {
    editAmountView.primaryAmountTextField.resignFirstResponder()
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  private func buildTransactionIfNecessary() {
    switch viewModel.direction {
    case .toLightning:
      buildTransaction()
    case .toOnChain:
      viewModel.direction = .toOnChain(viewModel.btcAmount)
    }
  }

  private func buildTransaction() {
    let paymentData = coordinationDelegate?.viewControllerNeedsTransactionData(self,
                                                                           btcAmount: viewModel.btcAmount,
                                                                           exchangeRates: rateManager.exchangeRates)
    viewModel.direction = .toLightning(paymentData)
  }

  private func setupTransactionUI() {
    switch viewModel.direction {
    case .toLightning(let data):
      feesView.isHidden = true
      data == nil ? disableConfirmButton() : enableConfirmButton()
    case .toOnChain(let inputs):
      inputs == nil ? disableConfirmButton() : enableConfirmButton()
    }
  }

  private func disableConfirmButton() {
    confirmView.isUserInteractionEnabled = false
    confirmView.alpha = 0.2
  }

  private func enableConfirmButton() {
    confirmView.isUserInteractionEnabled = true
    confirmView.alpha = 1.0
  }

  private func setupUI() {
    titleLabel.font = .regular(15)
    titleLabel.textColor = .darkBlueText
    switch viewModel.direction {
    case .toOnChain:
      titleLabel.text = "WITHDRAW FROM LIGHTNING"
      transferImageView.image = UIImage(imageLiteralResourceName: "lightningToBitcoinIcon")
    case .toLightning:
      titleLabel.text = "LOAD LIGHTNING"
      transferImageView.image = UIImage(imageLiteralResourceName: "bitcoinToLightningIcon")
    }

    setupKeyboardDoneButton(for: [editAmountView.primaryAmountTextField],
                            action: #selector(doneButtonWasPressed))

    setupTransactionUI()
  }

  @objc func doneButtonWasPressed() {
    editAmountView.primaryAmountTextField.resignFirstResponder()
    setupTransactionUI()
    buildTransactionIfNecessary()
  }
}

extension WalletTransferViewController: ConfirmViewDelegate {
  func viewDidConfirm() {
    switch viewModel.direction {
    case .toLightning(let data):
      guard let delegate = coordinationDelegate, let data = data else { return }
      delegate.viewControllerDidConfirmLoad(self, paymentData: data)
    case .toOnChain(let btcAmount):
      guard let delegate = coordinationDelegate, let btcAmount = btcAmount else { return }
      delegate.viewControllerDidConfirmWithdraw(self, btcAmount: btcAmount)
    }
  }
}

extension WalletTransferViewController: FeesViewDelegate {

  func tooltipButtonWasTouched() {
    // TODO: Implement
  }
}
