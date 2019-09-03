//
//  RequestPayViewController.swift
//  DropBit
//
//  Created by BJ Miller on 4/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PromiseKit
import SVProgressHUD

protocol RequestPayViewControllerDelegate: ViewControllerDismissable, CopyToClipboardMessageDisplayable, CurrencyValueDataSourceType {
  func viewControllerDidSelectSendRequest(_ viewController: UIViewController, payload: [Any])
  func viewControllerDidSelectCreateInvoice(_ viewController: UIViewController, forAmount amount: Int, withMemo memo: String?) -> Promise<LNDecodePaymentRequestResponse>
  func viewControllerDidRequestNextReceiveAddress(_ viewController: UIViewController) -> String?
  func selectedCurrencyPair() -> CurrencyPair
}

final class RequestPayViewController: PresentableViewController, StoryboardInitializable, CurrencySwappableAmountEditor {

  // MARK: outlets
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var walletToggleView: WalletToggleView!
  @IBOutlet var editAmountView: CurrencySwappableEditAmountView!
  @IBOutlet var qrImageView: UIImageView!
  @IBOutlet var memoTextField: UITextField!
  @IBOutlet var memoLabel: UILabel!
  @IBOutlet var expirationLabel: ExpirationLabel!
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
  @IBOutlet var bottomActionButton: PrimaryActionButton! {
    didSet {
      bottomActionButton.setTitle("SEND REQUEST", for: .normal)
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
    switch walletTransactionType {
    case .onChain:
      var payload: [Any] = []
      qrImageView.image.flatMap { $0.pngData() }.flatMap { payload.append($0) }
      if let viewModel = viewModel, let btcURL = viewModel.bitcoinURL {
        if let amount = btcURL.components.amount, amount > 0 {
          payload.append(btcURL.absoluteString) //include amount details
        } else if let address = btcURL.components.address {
          payload.append(address)
        }
      }
      coordinationDelegate?.viewControllerDidSelectSendRequest(self, payload: payload)
    case .lightning:
      if let lightningInvoice = lightningInvoice {
        var payload: [Any] = []
        qrImageView.image.flatMap { $0.pngData() }.flatMap { payload.append($0) }
        payload.append(lightningInvoice.paymentHash)
        coordinationDelegate?.viewControllerDidSelectSendRequest(self, payload: payload)
      } else {
        createLightningInvoice(withAmount: 100, memo: memoTextField.text) //TODO: add amount
      }
    }
  }

  @IBAction func addressTapped(_ sender: UITapGestureRecognizer) {
    UIPasteboard.general.string = viewModel.receiveAddress
    coordinationDelegate?.viewControllerSuccessfullyCopiedToClipboard(message: "Address copied to clipboard!", viewController: self)
  }

  // MARK: variables
  var coordinationDelegate: RequestPayViewControllerDelegate? {
    return generalCoordinationDelegate as? RequestPayViewControllerDelegate
  }

  let rateManager: ExchangeRateManager = ExchangeRateManager()
  var currencyValueManager: CurrencyValueDataSourceType?
  var viewModel: RequestPayViewModel! = RequestPayViewModel(receiveAddress: "",
                                                            viewModel: .emptyInstance(),
                                                            walletTransactionType: .onChain)
  var editAmountViewModel: CurrencySwappableEditAmountViewModel { return viewModel }

  var isModal: Bool = true
  var shouldHideEditAmountView = true
  var shouldHideAddAmountButton: Bool { return !shouldHideEditAmountView }
  var walletTransactionType: WalletTransactionType = .onChain
  var lightningInvoice: LNDecodePaymentRequestResponse?
  var hasLightningInvoice: Bool {
    return lightningInvoice != nil
  }

  var alertManager: AlertManager?

  private func createLightningInvoice(withAmount amount: Int, memo: String?) {
    SVProgressHUD.show()
    coordinationDelegate?.viewControllerDidSelectCreateInvoice(self, forAmount: amount, withMemo: memo)
      .get { response in
        SVProgressHUD.dismiss()
        self.lightningInvoice = response
        self.setupStyle()
      }.catch { error in
        SVProgressHUD.dismiss()
        if let alert = self.alertManager?.defaultAlert(withTitle: "Error", description: "There was an error when creating your invoice, please try again") {
          self.present(alert, animated: true, completion: nil)
        }
      }
  }

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
                          walletTransactionType: WalletTransactionType,
                          alertManager: AlertManager,
                          exchangeRates: ExchangeRates) -> RequestPayViewController {
    let vc = RequestPayViewController.makeFromStoryboard()
    vc.generalCoordinationDelegate = delegate
    vc.alertManager = alertManager
    let editAmountViewModel = CurrencySwappableEditAmountViewModel(exchangeRates: exchangeRates,
                                                                   primaryAmount: .zero,
                                                                   currencyPair: currencyPair,
                                                                   delegate: vc)
    vc.viewModel = RequestPayViewModel(receiveAddress: receiveAddress, viewModel: editAmountViewModel,
                                       walletTransactionType: walletTransactionType)
    return vc
  }

  // MARK: view lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    closeButton.isHidden = !isModal
    setupCurrencySwappableEditAmountView()
    registerForRateUpdates()
    updateRatesAndView()
    walletToggleView.delegate = self
    setupKeyboardDoneButton(for: [editAmountView.primaryAmountTextField],
                            action: #selector(doneButtonWasPressed))
  }

  @objc func doneButtonWasPressed() {
    editAmountView.primaryAmountTextField.resignFirstResponder()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    resetViewModel()
    setupStyle()
    updateViewWithViewModel()
  }

  func resetViewModel() {
    shouldHideEditAmountView = true

    guard let delegate = coordinationDelegate,
      let nextAddress = delegate.viewControllerDidRequestNextReceiveAddress(self)
      else { return }

    self.viewModel.currencyPair = delegate.selectedCurrencyPair()
    self.viewModel.fromAmount = .zero
    self.viewModel.receiveAddress = nextAddress
  }

  func setupStyle() {
    switch walletTransactionType {
    case .onChain:
      bottomActionButton.style = .bitcoin(true)
      bottomActionButton.setTitle("SEND REQUEST", for: .normal)
    case .lightning:
      setupStyleForLightningRequest()
    }
  }

  private func setupStyleForLightningRequest() {
    if let invoice = lightningInvoice {
      memoTextField.isHidden = true
      memoLabel.text = invoice.description
      bottomActionButton.setTitle("SEND REQUEST", for: .normal)
    } else {
      bottomActionButton.setTitle("CREATE INVOICE", for: .normal)
      bottomActionButton.style = .lightning(true)
    }
  }

  func updateViewWithViewModel() {
    receiveAddressLabel.text = viewModel.receiveAddress
    updateQRImage()
    let labels = viewModel.dualAmountLabels()
    editAmountView.configure(withLabels: labels, delegate: self)
    showHideEditAmountView()
  }

  func updateQRImage() {
    qrImageView.image = viewModel.qrImage(withSize: qrImageView.frame.size)
  }

}

extension RequestPayViewController: WalletToggleViewDelegate {

  func bitcoinWalletButtonWasTouched() {
    walletTransactionType = .onChain
    setupStyle()
  }

  func lightningWalletButtonWasTouched() {
    walletTransactionType = .lightning
    setupStyle()
  }

}
