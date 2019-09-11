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
  func viewControllerDidCreateInvoice(_ viewController: UIViewController)
  func viewControllerDidSelectSendRequest(_ viewController: UIViewController, payload: [Any])
  func viewControllerDidSelectCreateInvoice(_ viewController: UIViewController,
                                            forAmount sats: Int,
                                            withMemo memo: String?) -> Promise<LNCreatePaymentRequestResponse>
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
  @IBOutlet var receiveAddressLabel: UILabel!
  @IBOutlet var receiveAddressTapGesture: UITapGestureRecognizer!
  @IBOutlet var receiveAddressBGView: UIView!
  @IBOutlet var tapInstructionLabel: UILabel!
  @IBOutlet var bottomActionButton: PrimaryActionButton!
  @IBOutlet var addAmountButton: UIButton!

  @IBAction func closeButtonTapped(_ sender: UIButton) {
    editAmountView.primaryAmountTextField.resignFirstResponder()
    delegate.viewControllerDidSelectClose(self)
  }

  @IBAction func addRequestAmountButtonTapped(_ sender: UIButton) {
    shouldHideEditAmountView = false
    showHideEditAmountView()
    editAmountView.primaryAmountTextField.becomeFirstResponder()
  }

  @IBAction func sendRequestButtonTapped(_ sender: UIButton) {
    editAmountView.primaryAmountTextField.resignFirstResponder()
    switch viewModel.walletTransactionType {
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
      delegate.viewControllerDidSelectSendRequest(self, payload: payload)
    case .lightning:
      if let lightningInvoice = viewModel.lightningInvoice {
        var payload: [Any] = []
        qrImageView.image.flatMap { $0.pngData() }.flatMap { payload.append($0) }
        payload.append(lightningInvoice.request)
        delegate.viewControllerDidSelectSendRequest(self, payload: payload)
      } else {

        createLightningInvoice(withAmount: viewModel.btcAmount.asFractionalUnits(of: .BTC), memo: memoTextField.text)
      }
    }
  }

  @IBAction func addressTapped(_ sender: UITapGestureRecognizer) {
    switch viewModel.walletTransactionType {
    case .onChain:
      delegate.viewControllerSuccessfullyCopiedToClipboard(message: "Address copied to clipboard!", viewController: self)
      UIPasteboard.general.string = viewModel.receiveAddress
    case .lightning:
      guard let invoice = viewModel.lightningInvoice?.request else { return }
      delegate.viewControllerSuccessfullyCopiedToClipboard(message: "Invoice copied to clipboard!", viewController: self)
      UIPasteboard.general.string = invoice
    }
  }

  // MARK: variables
  private(set) weak var delegate: RequestPayViewControllerDelegate!
  private(set) weak var alertManager: AlertManagerType?

  let rateManager: ExchangeRateManager = ExchangeRateManager()
  var currencyValueManager: CurrencyValueDataSourceType?
  var viewModel: RequestPayViewModel!
  var editAmountViewModel: CurrencySwappableEditAmountViewModel { return viewModel }

  var isModal: Bool = true
  var shouldHideEditAmountView = true
  var shouldHideAddAmountButton: Bool { return !shouldHideEditAmountView }
  var hasLightningInvoice: Bool {
    return viewModel.lightningInvoice != nil
  }

  static func newInstance(delegate: RequestPayViewControllerDelegate,
                          viewModel: RequestPayViewModel?,
                          alertManager: AlertManagerType?) -> RequestPayViewController {
    let vc = RequestPayViewController.makeFromStoryboard()
    vc.delegate = delegate
    vc.viewModel = viewModel ?? RequestPayViewModel(receiveAddress: "", amountViewModel: .emptyInstance())
    vc.viewModel.delegate = vc
    vc.alertManager = alertManager
    return vc
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .requestPay(.page)),
      (receiveAddressLabel, .requestPay(.addressLabel))
    ]
  }

  // MARK: view lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    setupSubviews()

    editAmountView.disableSwap()
    setupCurrencySwappableEditAmountView()
    registerForRateUpdates()
    updateRatesAndView()
    walletToggleView.delegate = self
    setupKeyboardDoneButton(for: [editAmountView.primaryAmountTextField, memoTextField],
                            action: #selector(doneButtonWasPressed))
  }

  @objc func doneButtonWasPressed() {
    memoTextField.resignFirstResponder()
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

    guard let nextAddress = delegate.viewControllerDidRequestNextReceiveAddress(self) else { return }
    self.viewModel.currencyPair = delegate.selectedCurrencyPair()
    self.viewModel.fromAmount = .zero
    self.viewModel.receiveAddress = nextAddress
  }

  func setupStyle() {
    switch viewModel.walletTransactionType {
    case .onChain:
      receiveAddressBGView.isHidden = false
      tapInstructionLabel.isHidden = false
      qrImageView.isHidden = false
      receiveAddressLabel.isHidden = false
      memoTextField.isHidden = true
      walletToggleView.selectBitcoinButton()
      bottomActionButton.style = .bitcoin(true)
      bottomActionButton.setTitle("SEND REQUEST", for: .normal)
    case .lightning:
      setupStyleForLightningRequest()
    }
  }

  private func setupSubviews() {
    receiveAddressLabel.textColor = .darkBlueText
    receiveAddressLabel.font = .semiBold(13)

    receiveAddressBGView.applyCornerRadius(4)
    receiveAddressBGView.layer.borderColor = UIColor.mediumGrayBorder.cgColor
    receiveAddressBGView.layer.borderWidth = 2.0
    receiveAddressBGView.backgroundColor = .clear

    tapInstructionLabel.textColor = .darkGrayText
    tapInstructionLabel.font = .medium(10)

    bottomActionButton.setTitle("SEND REQUEST", for: .normal)

    addAmountButton.styleAddButtonWith(title: "Add Receive Amount")

    closeButton.isHidden = !isModal
    memoTextField.backgroundColor = .lightGrayBackground
    memoTextField.autocorrectionType = .no
    memoTextField.font = .medium(14)
    memoLabel.font = .light(14)
  }

  private func setupStyleForLightningRequest() {
    if let invoice = viewModel.lightningInvoice {
      qrImageView.isHidden = false
      addAmountButton.isHidden = true
      expirationLabel.isHidden = false
      tapInstructionLabel.isHidden = false
      receiveAddressLabel.text = invoice.request
      receiveAddressLabel.isHidden = false
      receiveAddressBGView.isHidden = false
      bottomActionButton.style = .bitcoin(true)
      memoTextField.isHidden = true
      walletToggleView.isHidden = true
      memoLabel.isHidden = false
      memoLabel.text = memoTextField.text
      bottomActionButton.setTitle("SEND REQUEST", for: .normal)
      tapInstructionLabel.text = "TAP INVOICE TO SAVE TO CLIPBOARD"
    } else {
      qrImageView.isHidden = true
      memoTextField.isHidden = false
      tapInstructionLabel.isHidden = true
      receiveAddressLabel.isHidden = true
      receiveAddressBGView.isHidden = true
      bottomActionButton.setTitle("CREATE INVOICE", for: .normal)
    }

    walletToggleView.selectLightningButton()
    bottomActionButton.style = .lightning(true)
  }

  func updateViewWithViewModel() {
    switch viewModel.walletTransactionType {
    case .lightning:
      if let invoice = viewModel.lightningInvoice {
        receiveAddressLabel.text = invoice.request
      }
    case .onChain:
      receiveAddressLabel.text = viewModel.receiveAddress
    }

    updateQRImage()
    let labels = viewModel.dualAmountLabels(walletTransactionType: viewModel.walletTransactionType)
    editAmountView.configure(withLabels: labels, delegate: self)
    showHideEditAmountView()
  }

  func updateQRImage() {
    qrImageView.image = viewModel.qrImage(withSize: qrImageView.frame.size)
  }

  private func createLightningInvoice(withAmount amount: Int, memo: String?) {
    SVProgressHUD.show()
    delegate.viewControllerDidSelectCreateInvoice(self, forAmount: amount, withMemo: memo)
      .get { response in
        SVProgressHUD.dismiss()
        self.viewModel.lightningInvoice = response
        self.editAmountView.isUserInteractionEnabled = false
        self.delegate.viewControllerDidCreateInvoice(self)
        self.setupStyle()
        self.updateViewWithViewModel()
      }.catch { error in
        SVProgressHUD.dismiss()
        if let alert = self.alertManager?.defaultAlert(withTitle: "Error", description: error.localizedDescription) {
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

}

extension RequestPayViewController: WalletToggleViewDelegate {

  func bitcoinWalletButtonWasTouched() {
    viewModel.walletTransactionType = .onChain
    setupStyle()
    updateViewWithViewModel()
  }

  func lightningWalletButtonWasTouched() {
    viewModel.walletTransactionType = .lightning
    setupStyle()
    updateViewWithViewModel()
  }

}
