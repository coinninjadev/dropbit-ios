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

protocol WalletTransferViewControllerDelegate: ViewControllerDismissable
& PaymentBuildingDelegate & PaymentSendingDelegate & URLOpener &
BalanceDataSource & AnalyticsManagerAccessType {

  func viewControllerNeedsTransactionData(_ viewController: UIViewController,
                                          btcAmount: NSDecimalNumber,
                                          exchangeRates: ExchangeRates) -> Promise<PaymentData>

  func viewControllerDidConfirmLoad(_ viewController: UIViewController,
                                    paymentData: PaymentData)

  func viewControllerNeedsFeeEstimates(_ viewController: UIViewController, btcAmount: NSDecimalNumber) -> Promise<LNTransactionResponse>

  func viewControllerDidConfirmWithdraw(_ viewController: UIViewController, btcAmount: NSDecimalNumber)
  func viewControllerNetworkError(_ error: Error)
  func handleLightningLoadError(_ error: Error)
}

enum TransferDirection {
  case toLightning(PaymentData?) //load
  case toOnChain(NSDecimalNumber?) //withdraw
}

class WalletTransferViewController: PresentableViewController, StoryboardInitializable, CurrencySwappableAmountEditor, PaymentAmountValidatable {

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
    viewController.delegate = delegate
    viewModel.delegate = viewController
    return viewController
  }

  var editAmountViewModel: CurrencySwappableEditAmountViewModel {
    return viewModel
  }

  private(set) weak var delegate: WalletTransferViewControllerDelegate!
  var currencyValueManager: CurrencyValueDataSourceType? {
    return delegate as? CurrencyValueDataSourceType
  }

  var balanceDataSource: BalanceDataSource? {
    return delegate
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    switch viewModel.direction {
    case .toOnChain:
      delegate.viewControllerShouldTrackEvent(event: .lightningToOnChainPressed)
    case .toLightning:
      delegate.viewControllerShouldTrackEvent(event: .onChainToLightningPressed)
    }

    confirmView.delegate = self
    feesView.delegate = self
    editAmountView.delegate = self
    refreshBothAmounts()
    setupUI()
    setupCurrencySwappableEditAmountView()
    registerForRateUpdates()
    updateRatesAndView()
    buildTransactionIfNecessary()
  }

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    updateEditAmountView(withRates: exchangeRateManager.exchangeRates)
  }

  @IBAction func closeButtonWasTouched() {
    editAmountView.primaryAmountTextField.resignFirstResponder()
    delegate.viewControllerDidSelectCloseWithToggle(self)
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
    guard viewModel.btcAmount > 0 else {
      self.disableConfirmButton()
      return
    }
    let walletBalances = balanceDataSource?.balancesNetPending() ?? .empty
    do {
      try LightningWalletAmountValidator(balancesNetPending: walletBalances, walletType: .onChain)
        .validate(value: viewModel.currencyConverter)
      delegate.viewControllerNeedsTransactionData(self, btcAmount: viewModel.btcAmount, exchangeRates: viewModel.exchangeRates)
        .done { paymentData in
          self.viewModel.direction = .toLightning(paymentData)
          self.setupTransactionUI()
        }
        .catch {
          self.delegate.handleLightningLoadError($0)
          self.disableConfirmButton()
      }
    } catch {
      self.delegate.handleLightningLoadError(error)
    }
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
    getFeeEstimatesIfNecessary()
  }

  private func getFeeEstimatesIfNecessary() {
    switch viewModel.direction {
    case .toOnChain(let amount):
      guard let amount = amount, amount > 0 else {
        feesView.isHidden = true
        confirmView.disable()
        return
      }
      SVProgressHUD.show()

      do {
        let walletBalances: WalletBalances = balanceDataSource?.balancesNetPending() ?? .empty
        let type = WalletTransactionType.lightning
        let value = CurrencyConverter(fromBtcTo: .USD, fromAmount: amount, rates: rateManager.exchangeRates)
        try LightningWalletAmountValidator(balancesNetPending: walletBalances,
                                           walletType: type,
                                           ignoring: [.maxWalletValue]).validate(value: value)

        delegate.viewControllerNeedsFeeEstimates(self, btcAmount: amount)
          .get(on: .main) { response in
            SVProgressHUD.dismiss()
            self.setupUIForFees(networkFee: response.result.networkFee, processingFee: response.result.processingFee)
        }.catch { error in
          SVProgressHUD.dismiss()
          self.delegate.viewControllerNetworkError(error)
        }
      } catch {
        delegate.handleLightningLoadError(error)
      }

    default:
      break
    }
  }

  private func setupUIForFees(networkFee: Int, processingFee: Int) {
    feesView.isHidden = false
    feesView.setupFees(top: networkFee, bottom: processingFee)
  }
}

extension WalletTransferViewController: ConfirmViewDelegate {
  func viewDidConfirm() {
    do {
      try CurrencyAmountValidator(balancesNetPending: delegate.balancesNetPending(),
                                  balanceToCheck: viewModel.walletTransactionType,
                                  ignoring: [.invitationMaximum]).validate(value:
                                    viewModel.currencyConverter)
    } catch {
      delegate.viewControllerNetworkError(error)
    }

    let walletBalances = balanceDataSource?.balancesNetPending() ?? .empty
    switch viewModel.direction {
    case .toLightning(let data):
      guard let data = data else { return }
      do {
        try LightningWalletAmountValidator(balancesNetPending: walletBalances, walletType: .onChain)
          .validate(value: viewModel.currencyConverter)
        delegate.viewControllerDidConfirmLoad(self, paymentData: data)
      } catch {
        delegate.viewControllerNetworkError(error)
      }
    case .toOnChain(let btcAmount):
      guard let btcAmount = btcAmount else { return }
      do {
        let lightningBalanceValidator = CurrencyAmountValidator(balancesNetPending: walletBalances,
                                                                balanceToCheck: .lightning,
                                                                ignoring: [.invitationMaximum])
        try lightningBalanceValidator.validate(value: viewModel.currencyConverter)
        delegate.viewControllerDidConfirmWithdraw(self, btcAmount: btcAmount)
      } catch {
        delegate.viewControllerNetworkError(error)
      }
    }
  }
}

extension WalletTransferViewController: FeesViewDelegate {

  func tooltipButtonWasTouched() {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .dropBitAppLightningWithdrawalFees) else { return }
    delegate.openURL(url, completionHandler: nil)
  }
}
