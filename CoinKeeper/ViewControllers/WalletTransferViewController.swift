//
//  WalletTransferViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

enum TransferAmount {
  case low
  case medium
  case high
  case max
  case custom

  var value: Int {
    switch self {
    case .low: return 5
    case .medium: return 20
    case .high: return 50
    case .max: return 100
    case .custom: return 0
    }
  }
}

protocol WalletTransferViewControllerDelegate: ViewControllerDismissable {
  func viewControllerDidConfirmTransfer()
}

class WalletTransferViewController: PresentableViewController, StoryboardInitializable, CurrencySwappableAmountEditor {

  var rateManager: ExchangeRateManager = ExchangeRateManager()

  enum TransferType {
    case toLightning
    case toOnChain
  }

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

  var currencyValueManager: CurrencyValueDataSourceType? {
    didSet {
      currencyValueManager = generalCoordinationDelegate as? CurrencyValueDataSourceType
    }
  }

  var coordinationDelegate: WalletTransferViewControllerDelegate? {
    return generalCoordinationDelegate as? WalletTransferViewControllerDelegate
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    confirmView.delegate = self
    feesView.delegate = self
    let labels = viewModel.dualAmountLabels()
    editAmountView.configure(withLabels: labels, delegate: self)
    setupUI()
    setupCurrencySwappableEditAmountView()
  }

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    updateEditAmountView(withRates: exchangeRateManager.exchangeRates)
  }

  @IBAction func closeButtonWasTouched() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  private func setupUI() {
    titleLabel.font = .regular(15)
    titleLabel.textColor = .darkBlueText
    switch viewModel.transferType {
    case .toOnChain:
      titleLabel.text = "WITHDRAWL FROM LIGHTNING"
      transferImageView.image = UIImage(imageLiteralResourceName: "lightningToBitcoinIcon")
    case .toLightning:
      titleLabel.text = "LOAD LIGHTNING"
      transferImageView.image = UIImage(imageLiteralResourceName: "bitcoinToLightningIcon")
    }

  }
}

extension WalletTransferViewController: ConfirmViewDelegate {

  func viewDidConfirm() {
    coordinationDelegate?.viewControllerDidConfirmTransfer()
  }
}

extension WalletTransferViewController: FeesViewDelegate {

  func tooltipButtonWasTouched() {

  }
}
