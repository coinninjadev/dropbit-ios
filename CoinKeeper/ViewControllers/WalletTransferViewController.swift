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

protocol WalletTransferViewControllerDelegate:
  ViewControllerDismissable, PaymentBuildingDelegate, PaymentSendingDelegate {

  func viewControllerNeedsTransactionData(_ viewController: UIViewController,
                                          direction: TransferDirection,
                                          btcAmount: NSDecimalNumber,
                                          exchangeRates: ExchangeRates) -> PaymentData?

  func viewControllerDidConfirmLoad(_ viewController: UIViewController,
                                        paymentData: PaymentData)

  func viewControllerDidConfirmWithdraw(_ viewController: UIViewController,
                                        lightningData: LightningPaymentInputs)
}

enum TransferDirection {
  case toLightning //load
  case toOnChain //withdraw
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
    let labels = viewModel.dualAmountLabels()
    editAmountView.configure(withLabels: labels, delegate: self)
    currencyValueManager = generalCoordinationDelegate as? CurrencyValueDataSourceType
    setupUI()
    setupCurrencySwappableEditAmountView()

    if viewModel.direction == .toLightning {
      SVProgressHUD.show()
      buildTransaction()
    }
  }

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    updateEditAmountView(withRates: exchangeRateManager.exchangeRates)
  }

  @IBAction func closeButtonWasTouched() {
    editAmountView.primaryAmountTextField.resignFirstResponder()
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  private func buildTransaction() {

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

  }

  @objc func doneButtonWasPressed() {
    editAmountView.primaryAmountTextField.resignFirstResponder()
  }

}

extension WalletTransferViewController: ConfirmViewDelegate {

  func viewDidConfirm() {
    //TODO: Check what type of transfer it is and call correct function
  }
}

extension WalletTransferViewController: FeesViewDelegate {

  func tooltipButtonWasTouched() {
    // TODO: Implement
  }
}
