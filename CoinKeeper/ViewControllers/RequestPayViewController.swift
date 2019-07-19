//
//  RequestPayViewController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol RequestPayViewControllerDelegate: ViewControllerDismissable, CopyToClipboardMessageDisplayable, CurrencyValueDataSourceType {
  func viewControllerDidSelectSendRequest(_ viewController: UIViewController, payload: [Any])
  func viewControllerDidRequestNextReceiveAddress(_ viewController: UIViewController) -> String?
}

final class RequestPayViewController: PresentableViewController, StoryboardInitializable, CurrencySwappableAmountEditor {

  // MARK: outlets
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.font = .regular(15)
      titleLabel.textColor = .darkBlueText
    }
  }
  @IBOutlet var editAmountView: CurrencySwappableEditAmountView!
  @IBOutlet var qrImageView: UIImageView!
  @IBOutlet var receiveAddressLabel: UILabel! {
    didSet {
      receiveAddressLabel.textColor = .darkBlueText
      receiveAddressLabel.font = .semiBold(13)
    }
  }
  @IBOutlet var receiveAddressTapGesture: UITapGestureRecognizer!
  @IBOutlet var receiveAddressBGView: UIView! {
    didSet {
      receiveAddressBGView.applyCornerRadius(4)
      receiveAddressBGView.layer.borderColor = UIColor.mediumGrayBorder.cgColor
      receiveAddressBGView.layer.borderWidth = 2.0
      receiveAddressBGView.backgroundColor = .clear
    }
  }
  @IBOutlet var tapInstructionLabel: UILabel! {
    didSet {
      tapInstructionLabel.textColor = .darkGrayText
      tapInstructionLabel.font = .medium(10)
    }
  }
  @IBOutlet var sendRequestButton: PrimaryActionButton! {
    didSet {
      sendRequestButton.setTitle("SEND REQUEST", for: .normal)
    }
  }

  @IBOutlet var addAmountButton: UIButton! {
    didSet {
      addAmountButton.styleAddButtonWith(title: "Add Receive Amount")
    }
  }

  @IBAction func closeButtonTapped(_ sender: UIButton) {
    editAmountView.primaryAmountTextField.resignFirstResponder()
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  @IBAction func addRequestAmountButtonTapped(_ sender: UIButton) {
    shouldHideEditAmountView = false
    showHideEditAmountView()
    editAmountView.primaryAmountTextField.becomeFirstResponder()
  }

  @IBAction func sendRequestButtonTapped(_ sender: UIButton) {
    var payload: [Any] = []
    qrImageView.image.flatMap { $0.pngData() }.flatMap { payload.append($0) }
    if let viewModel = viewModel {
      if let amount = viewModel.bitcoinUrl.components.amount, amount > 0 {
        payload.append(viewModel.bitcoinUrl.absoluteString) //include amount details
      } else if let address = viewModel.bitcoinUrl.components.address {
        payload.append(address)
      }
    }
    coordinationDelegate?.viewControllerDidSelectSendRequest(self, payload: payload)
  }

  @IBAction func addressTapped(_ sender: UITapGestureRecognizer) {
    UIPasteboard.general.string = viewModel.bitcoinUrl.components.address
    coordinationDelegate?.viewControllerSuccessfullyCopiedToClipboard(message: "Address copied to clipboard!", viewController: self)
  }

  // MARK: variables
  var coordinationDelegate: RequestPayViewControllerDelegate? {
    return generalCoordinationDelegate as? RequestPayViewControllerDelegate
  }

  let rateManager: ExchangeRateManager = ExchangeRateManager()
  var currencyValueManager: CurrencyValueDataSourceType?
  var viewModel: RequestPayViewModel! = RequestPayViewModel(receiveAddress: "",
                                                            viewModel: .emptyInstance())
  var editAmountViewModel: CurrencySwappableEditAmountViewModel { return viewModel }

  var isModal: Bool = true
  var shouldHideEditAmountView = true //hide by default
  var shouldHideAddAmountButton: Bool { return !shouldHideEditAmountView }

  func showHideEditAmountView() {
    editAmountView.isHidden = shouldHideEditAmountView
    addAmountButton.isHidden = shouldHideAddAmountButton
  }

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    updateEditAmountView(withRates: exchangeRateManager.exchangeRates)
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .requestPay(.page)),
      (receiveAddressLabel, .requestPay(.addressLabel))
    ]
  }

  static func newInstance(delegate: RequestPayViewControllerDelegate,
                          receiveAddress: String,
                          currencyPair: CurrencyPair,
                          exchangeRates: ExchangeRates) -> RequestPayViewController {
    let vc = RequestPayViewController.makeFromStoryboard()
    vc.generalCoordinationDelegate = delegate
    let editAmountViewModel = CurrencySwappableEditAmountViewModel(exchangeRates: exchangeRates,
                                                                   primaryAmount: .zero,
                                                                   currencyPair: currencyPair,
                                                                   delegate: vc)
    vc.viewModel = RequestPayViewModel(receiveAddress: receiveAddress, viewModel: editAmountViewModel)
    return vc
  }

  // MARK: view lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    closeButton.isHidden = !isModal
    setupCurrencySwappableEditAmountView()
    registerForRateUpdates()
    updateRatesAndView()
    setupKeyboardDoneButton(for: [editAmountView.primaryAmountTextField],
                            action: #selector(doneButtonWasPressed))
  }

  @objc func doneButtonWasPressed() {
    editAmountView.primaryAmountTextField.resignFirstResponder()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateViewWithViewModel()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    resetViewModel()
  }

  func resetViewModel() {
    shouldHideEditAmountView = true

    guard let delegate = coordinationDelegate,
      let currentVM = self.viewModel,
      let nextAddress = delegate.viewControllerDidRequestNextReceiveAddress(self)
      else { return }

    let newSwappableVM = CurrencySwappableEditAmountViewModel(exchangeRates: currentVM.exchangeRates,
                                                              primaryAmount: .zero,
                                                              currencyPair: currentVM.currencyPair)
    let newViewModel = RequestPayViewModel(receiveAddress: nextAddress, viewModel: newSwappableVM)
    self.viewModel = newViewModel
    updateViewWithViewModel()
  }

  func updateViewWithViewModel() {
    receiveAddressLabel.text = viewModel.bitcoinUrl.components.address
    qrImageView.image = viewModel.qrImage(withSize: qrImageView.frame.size)
    let labels = viewModel.dualAmountLabels()
    editAmountView.configure(withLabels: labels, delegate: self)
    showHideEditAmountView()
  }

}

extension RequestPayViewController: CurrencySwappableEditAmountViewModelDelegate {

  func viewModelDidEndEditingAmount(_ viewModel: CurrencySwappableEditAmountViewModel) {

  }

  func viewModelDidSwapCurrencies(_ viewModel: CurrencySwappableEditAmountViewModel) {

  }

}
