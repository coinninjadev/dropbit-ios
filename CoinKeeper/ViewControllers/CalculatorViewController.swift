//
//  CalculatorViewController.swift
//  CoinKeeper
//
//  Created by Ben Winters on 3/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol CalculatorViewControllerDelegate: ConvertibleBalanceProvider & BalanceContainerDelegate & BadgeUpdateDelegate {
  func viewControllerDidTapScan(_ viewController: UIViewController, converter: CurrencyConverter)
  func viewControllerDidTapReceivePayment(_ viewController: UIViewController, converter: CurrencyConverter)
  func viewControllerDidTapSendPayment(_ viewController: UIViewController, converter: CurrencyConverter)
  func viewControllerDidTapSendPaymentWithInvalidAmount(_ viewController: UIViewController, error: ValidatorTypeError)
  func requireAuthenticationIfNeeded(whenAuthenticated: (() -> Void)?)
  func badgingManager() -> BadgeManagerType
}

final class CalculatorViewController: BaseViewController, StoryboardInitializable, PaymentAmountValidatable {

  @IBOutlet var balanceContainer: BalanceContainer!
  @IBOutlet var keypadView: KeypadEntryView!
  @IBOutlet var primaryAmountLabel: CalculatorPrimaryAmountLabel!
  @IBOutlet var secondaryAmountLabel: CalculatorSecondaryAmountLabel!
  @IBOutlet var currencyToggle: CalculatorCurrencyToggle!
  @IBOutlet var receiveButton: UIButton!
  @IBOutlet var scanButton: UIButton!
  @IBOutlet var sendButton: UIButton!

  @IBAction func didTapScan(_ sender: Any) {
    coordinationDelegate?.viewControllerDidTapScan(self, converter: viewModel.currencyConverter)
  }

  @IBAction func didTapReceive(_ sender: Any) {
    coordinationDelegate?.viewControllerDidTapReceivePayment(self, converter: viewModel.currencyConverter)
  }

  @IBAction func didTapSend(_ sender: Any) {
    let converter = viewModel.currencyConverter
    do {
      try currencyAmountValidator.validate(value: converter)
      coordinationDelegate?.viewControllerDidTapSendPayment(self, converter: viewModel.currencyConverter)
    } catch let error as ValidatorTypeError {
      coordinationDelegate?.viewControllerDidTapSendPaymentWithInvalidAmount(self, error: error)
    } catch {
      print("didTapSend error: \(error.localizedDescription)")
    }
  }

  override var generalCoordinationDelegate: AnyObject? {
    didSet {
      // generalCoordinationDelegate is nil when viewDidLoad is called
      balanceContainer.delegate = coordinationDelegate
      (coordinationDelegate?.badgingManager()).map(subscribeToBadgeNotifications)
      coordinationDelegate?.viewControllerDidRequestBadgeUpdate(self)
    }
  }
  var coordinationDelegate: CalculatorViewControllerDelegate? {
    return generalCoordinationDelegate as? CalculatorViewControllerDelegate
  }

  var balanceProvider: ConvertibleBalanceProvider? { return coordinationDelegate }
  var balanceDataSource: BalanceDataSource? { return balanceProvider }

  var balanceNotificationToken: NotificationToken?
  var badgeNotificationToken: NotificationToken?

  var currencyAmountValidator: CurrencyAmountValidator {
    return createCurrencyAmountValidator(ignoring: [.transactionMinimum, .invitationMaximum])
  }

  let viewModel = CalculatorViewModel(currentAmountString: "", currentCurrencyCode: .USD)
  var analyticsManager: AnalyticsManagerType = AnalyticsManager()

  let rateManager = ExchangeRateManager()

  private var txNotificationToken: NotificationToken?

  private func updateView(with labels: CalculatorViewLabels) {
    primaryAmountLabel.attributedText = labels.currentAmount
    secondaryAmountLabel.attributedText = labels.convertedAmount
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = true
  }

  private func applyChange(_ change: CalculatorViewModelChange) {
    viewModel.apply(change)
    updateView(with: viewModel.labels)
    currencyToggle.update(with: viewModel.currencyToggleConfig)
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .calculator(.page)),
      (receiveButton, .calculator(.receiveButton)),
      (sendButton, .calculator(.sendButton))
    ]
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    keypadView.delegate = self
    currencyToggle.delegate = self

    subscribeToRateAndBalanceUpdates()
    subscribeToTransactionNotifications()

    updateView(with: viewModel.labels)
    currencyToggle.update(with: viewModel.currencyToggleConfig)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    updateRatesAndBalances()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private func subscribeToTransactionNotifications() {
    txNotificationToken = CKNotificationCenter.subscribe(key: .didSendTransactionSuccessfully, object: nil, queue: nil) { [weak self] (_) in
      self?.resetCalculator()
      self?.updateRatesAndBalances()
    }
  }

  private func resetCalculator() {
    applyChange(.reset)
  }

}

extension CalculatorViewController: BadgeDisplayable {

  func didReceiveBadgeUpdate(badgeInfo: BadgeInfo) {
    self.balanceContainer.leftButton.updateBadge(with: badgeInfo)
  }

}

extension CalculatorViewController: BalanceDisplayable {

  var balanceLeftButtonType: BalanceContainerLeftButtonType { return .menu }
  var primaryBalanceCurrency: CurrencyCode { return .BTC }

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    self.applyChange(.exchangeRates(exchangeRateManager.exchangeRates))
  }

}

extension CalculatorViewController: CalculatorCurrencyToggleDelegate {

  func didTapLeftCurrencyButton() {
    applyChange(.currency(.USD))
  }

  func didTapRightCurrencyButton() {
    applyChange(.currency(.BTC))
  }

}

extension CalculatorViewController: KeypadEntryViewDelegate {

  func selected(digit: String) {
    applyChange(.append(digit: digit))
  }

  func selectedDecimal() {
    applyChange(.decimal)
  }

  func selectedBack() {
    applyChange(.backspace)
  }

}
