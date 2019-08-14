//
//  ConfirmPaymentViewController.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import CNBitcoinKit

protocol ConfirmPaymentViewControllerDelegate: ViewControllerDismissable {
  func confirmPaymentViewControllerDidLoad(_ viewController: UIViewController)
  func viewControllerDidConfirmOnChainPayment(
    _ viewController: UIViewController,
    transactionData: CNBTransactionData,
    rates: ExchangeRates,
    outgoingTransactionData: OutgoingTransactionData
  )

  func viewControllerDidConfirmLightningPayment(
    _ viewController: UIViewController,
    inputs: LightningPaymentInputs)

  func viewControllerDidConfirmInvite(_ viewController: UIViewController,
                                      outgoingInvitationDTO: OutgoingInvitationDTO,
                                      walletTxType: WalletTransactionType)

  func viewControllerRequestedShowFeeTooExpensiveAlert(_ viewController: UIViewController)
}

typealias BitcoinUSDPair = (btcAmount: NSDecimalNumber, usdAmount: NSDecimalNumber)

class ConfirmPaymentViewController: PresentableViewController, StoryboardInitializable {

  static func newInstance(type: TransactionType,
                          viewModel: BaseConfirmPaymentViewModel,
                          feeModel: ConfirmTransactionFeeModel,
                          delegate: ConfirmPaymentViewControllerDelegate) -> ConfirmPaymentViewController {
    let vc = ConfirmPaymentViewController.makeFromStoryboard()
    vc.transactionType = type
    vc.viewModel = viewModel
    vc.feeModel = feeModel
    vc.generalCoordinationDelegate = delegate
    return vc
  }

  enum TransactionType {
    case invite, payment
  }

  private var transactionType: TransactionType = .payment
  private var viewModel: BaseConfirmPaymentViewModel!
  private var feeModel: ConfirmTransactionFeeModel!

  lazy private var confirmLongPressGestureRecognizer: UILongPressGestureRecognizer =
    UILongPressGestureRecognizer(target: self, action: #selector(confirmButtonDidConfirm))

  private var feedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

  @IBOutlet var walletTransactionTypeButton: CompactActionButton!
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var confirmButton: ConfirmPaymentButton!
  @IBOutlet var primaryCurrencyLabel: UILabel!
  @IBOutlet var secondaryCurrencyLabel: UILabel!
  @IBOutlet var networkFeeLabel: UILabel!
  @IBOutlet var adjustableFeesContainer: UIView!
  @IBOutlet var adjustableFeesControl: UISegmentedControl!
  @IBOutlet var adjustableFeesLabel: UILabel!
  @IBOutlet var contactLabel: UILabel!
  @IBOutlet var primaryAddressLabel: UILabel!
  @IBOutlet var memoContainerView: ConfirmPaymentMemoView!
  @IBOutlet var secondaryAddressLabel: UILabel!
  @IBOutlet var tapAndHoldLabel: UILabel!
  @IBOutlet var avatarBackgroundView: UIView!
  @IBOutlet var avatarImageView: UIImageView!

  var coordinationDelegate: ConfirmPaymentViewControllerDelegate? {
    return generalCoordinationDelegate as? ConfirmPaymentViewControllerDelegate
  }

  @IBAction func changeFeeType(_ sender: UISegmentedControl) {
    guard let model = feeModel else { return }
    switch model {
    case .adjustable(let adjustableModel):
      let selectedModel = adjustableModel.segmentModels[sender.selectedSegmentIndex]
      if selectedModel.isSelectable {
        let newAdjustableModel = adjustableModel.copy(selecting: selectedModel.type)
        self.feeModel = .adjustable(newAdjustableModel)
        self.viewModel.update(with: self.feeModel.transactionData)

      } else {
        coordinationDelegate?.viewControllerRequestedShowFeeTooExpensiveAlert(self)
      }

      self.updateFeeViews()
      self.updateAmountViews()
    default:
      break
    }
  }

  @IBAction func closeButtonWasTouched() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  @IBAction func confirmButtonWasHeld() {
    feedbackGenerator.impactOccurred()
    confirmButton.animate()
  }

  @IBAction func confirmButtonWasReleased() {
    confirmButton.reset()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    feedbackGenerator.prepare()
    confirmLongPressGestureRecognizer.allowableMovement = 1000
    confirmLongPressGestureRecognizer.minimumPressDuration = confirmButton.secondsToConfirm
    confirmButton.addGestureRecognizer(confirmLongPressGestureRecognizer)
    setupViews()

    coordinationDelegate?.confirmPaymentViewControllerDidLoad(self)

    updateViewWithModel()
  }

  @objc func confirmButtonDidConfirm() {
    if confirmLongPressGestureRecognizer.state == .began {
      switch transactionType {
      case .payment:
        routeConfirmedPayment(for: viewModel, feeModel: self.feeModel)
      case .invite:
        guard let inviteVM = viewModel as? ConfirmPaymentInviteViewModel else { return }
        self.confirmInvite(with: inviteVM, feeModel: feeModel)
      }
    }

    confirmButton.reset()
  }

  private func routeConfirmedPayment(for viewModel: BaseConfirmPaymentViewModel, feeModel: ConfirmTransactionFeeModel) {
    switch viewModel.walletTransactionType {
    case .onChain:
      guard let onChainVM = viewModel as? ConfirmOnChainPaymentViewModel else { return }
      confirmOnChainPayment(with: onChainVM, feeModel: feeModel)
    case .lightning:
      guard let lightningVM = viewModel as? ConfirmLightningPaymentViewModel else { return }
      confirmLightningPayment(with: lightningVM)
    }
  }

  private func confirmOnChainPayment(with viewModel: ConfirmOnChainPaymentViewModel,
                                     feeModel: ConfirmTransactionFeeModel) {
    guard let txData = feeModel.transactionData else {
      log.error("Transaction data is nil for on chain payment confirmation")
      return
    }

    var feeAdjustedOutgoingTxData = viewModel.outgoingTransactionData
    feeAdjustedOutgoingTxData.amount = Int(txData.amount)
    feeAdjustedOutgoingTxData.feeAmount = Int(txData.feeAmount)

    coordinationDelegate?.viewControllerDidConfirmOnChainPayment(
      self,
      transactionData: txData,
      rates: viewModel.exchangeRates,
      outgoingTransactionData: feeAdjustedOutgoingTxData
    )
  }

  private func confirmLightningPayment(with viewModel: ConfirmLightningPaymentViewModel) {
    let inputs = LightningPaymentInputs(sats: viewModel.btcAmount.asFractionalUnits(of: .BTC),
                                        invoice: viewModel.invoice,
                                        sharedPayload: viewModel.sharedPayloadDTO)
    coordinationDelegate?.viewControllerDidConfirmLightningPayment(self, inputs: inputs)
  }

  private func confirmInvite(with viewModel: ConfirmPaymentInviteViewModel,
                             feeModel: ConfirmTransactionFeeModel) {
    guard let contact = viewModel.contact else { return }
    let btcAmount = viewModel.btcAmount
    let converter = CurrencyConverter(fromBtcTo: .USD, fromAmount: btcAmount, rates: viewModel.exchangeRates)

    let pair = (btcAmount: btcAmount, usdAmount: converter.amount(forCurrency: .USD) ?? NSDecimalNumber(decimal: 0.0))
    let outgoingInvitationDTO = OutgoingInvitationDTO(contact: contact,
                                                      btcPair: pair,
                                                      fee: feeModel.networkFeeAmount,
                                                      sharedPayloadDTO: viewModel.sharedPayloadDTO)
    coordinationDelegate?.viewControllerDidConfirmInvite(self,
                                                         outgoingInvitationDTO: outgoingInvitationDTO,
                                                         walletTxType: viewModel.walletTransactionType)
  }

}

// MARK: - View Configuration

extension ConfirmPaymentViewController {

  fileprivate func setupViews() {
    primaryCurrencyLabel.textAlignment = .center
    primaryCurrencyLabel.textColor = .lightBlueTint
    primaryCurrencyLabel.font = .regular(35)

    secondaryCurrencyLabel.textAlignment = .center
    secondaryCurrencyLabel.textColor = .darkGrayText
    secondaryCurrencyLabel.font = .regular(17)

    networkFeeLabel.textAlignment = .center
    networkFeeLabel.font = .light(11)
    networkFeeLabel.textColor = .darkBlueText

    contactLabel.backgroundColor = UIColor.clear
    contactLabel.font = .regular(26)
    contactLabel.adjustsFontSizeToFitWidth = true

    primaryAddressLabel.backgroundColor = UIColor.clear
    primaryAddressLabel.font = .medium(14)
    primaryAddressLabel.adjustsFontSizeToFitWidth = true

    memoContainerView.isHidden = true

    secondaryAddressLabel.textAlignment = .center
    secondaryAddressLabel.textColor = .darkGrayText
    secondaryAddressLabel.font = .regular(13)

    tapAndHoldLabel.textColor = .darkGrayText
    tapAndHoldLabel.font = .medium(13)

    if let viewModel = viewModel {
      switch viewModel.walletTransactionType {
      case .lightning:
        walletTransactionTypeButton.style = .lightning(true)
        walletTransactionTypeButton.setAttributedTitle(NSAttributedString.lightningSelectedButtonTitle, for: .normal)
      case .onChain:
        walletTransactionTypeButton.style = .bitcoin(true)
        walletTransactionTypeButton.setAttributedTitle(NSAttributedString.bitcoinSelectedButton, for: .normal)
      }
    }

    adjustableFeesControl.tintColor = .primaryActionButton
    adjustableFeesControl.backgroundColor = .lightGrayBackground
    adjustableFeesControl.setTitleTextAttributes([
      .font: UIFont.medium(10),
      .foregroundColor: UIColor.deselectedGrayText
      ], for: .normal)
    adjustableFeesControl.setTitleTextAttributes([
      .font: UIFont.medium(10),
      .foregroundColor: UIColor.whiteText
      ], for: .selected)
  }

  fileprivate func updateViewWithModel() {
    guard viewModel != nil else { return }
    updateAmountViews()
    updateFeeViews()
    updateRecipientViews()
    updateMemoView()
  }

  fileprivate func updateAmountViews() {
    let converter = viewModel.generateCurrencyConverter(withBTCAmount: viewModel.btcAmount)
    let labels = viewModel.dualAmountLabels(withConverter: converter)
    primaryCurrencyLabel.text = labels.primary
    secondaryCurrencyLabel.attributedText = labels.secondary
  }

  fileprivate func updateFeeViews() {
    guard let feeModel = feeModel else { return }

    switch feeModel {
    case .adjustable(let vm):
      adjustableFeesContainer.isHidden = false
      adjustableFeesControl.selectedSegmentIndex = vm.selectedTypeIndex
      for (i, model) in vm.segmentModels.enumerated() {
        adjustableFeesControl.setTitle(model.title, forSegmentAt: i)
      }

      adjustableFeesLabel.attributedText = vm.attributedWaitTimeDescription

    case .required, .standard, .lightning:
      adjustableFeesContainer.isHidden = true
    }

    let feeDecimalAmount = NSDecimalNumber(integerAmount: feeModel.networkFeeAmount, currency: .BTC)
    let feeConverter = CurrencyConverter(fromBtcTo: .USD,
                                         fromAmount: feeDecimalAmount,
                                         rates: self.viewModel.exchangeRates)
    let btcFee = String(describing: feeConverter.amount(forCurrency: .BTC) ?? 0)
    let fiatFee = feeConverter.amountStringWithSymbol(forCurrency: .USD) ?? ""
    networkFeeLabel.text = "Network Fee \(btcFee) (\(fiatFee))"
  }

  fileprivate func updateRecipientViews() {
    // Hide address labels by default, unhide as needed
    // Contact label is always shown, set text to nil to hide
    primaryAddressLabel.isHidden = true
    secondaryAddressLabel.isHidden = true

    // Set default contact and address label values
    contactLabel.text = viewModel.contact?.displayName
    primaryAddressLabel.text = viewModel.destination
    secondaryAddressLabel.text = viewModel.destination

    if let contact = viewModel.contact {
      // May refer to either an actual contact or a manually entered phone number
      updateView(withContact: contact)
    } else {
      // Recipient is btc address
      primaryAddressLabel.isHidden = false
    }
  }

  private func updateView(withContact contact: ContactType) {
    var displayIdentity = ""

    avatarBackgroundView.isHidden = true
    contactLabel.isHidden = true

    switch contact.identityType {
    case .phone:
      guard let phoneContact = contact as? PhoneContactType else { return }
      contactLabel.isHidden = false
      let formatter = CKPhoneNumberFormatter(format: .international)
      displayIdentity = (try? formatter.string(from: phoneContact.globalPhoneNumber)) ?? ""
      avatarBackgroundView.isHidden = true
    case .twitter:
      displayIdentity = contact.displayIdentity
      guard let twitterContact = contact as? TwitterContact else { return }
      contactLabel.isHidden = true
      avatarBackgroundView.isHidden = false
      if let data = twitterContact.twitterUser.profileImageData {
        avatarImageView.image = UIImage(data: data)
        let radius = avatarImageView.frame.width / 2.0
        avatarImageView.applyCornerRadius(radius)
      }
    }

    switch contact.kind {
    case .generic:
      contactLabel.text = displayIdentity
      contactLabel.isHidden = false
      secondaryAddressLabel.isHidden = false
    case .invite:
      if contact.displayName == nil {
        contactLabel.text = displayIdentity
      } else {
        primaryAddressLabel.text = displayIdentity
        primaryAddressLabel.isHidden = false
      }
    case .registeredUser:
      primaryAddressLabel.text = displayIdentity
      primaryAddressLabel.isHidden = false // phone number
      secondaryAddressLabel.isHidden = false // address
    }
  }

  fileprivate func updateMemoView() {
    if let memo = viewModel.memo {
      memoContainerView.isHidden = false

      memoContainerView.configure(memo: memo,
                                  isShared: viewModel.shouldShareMemo,
                                  isSent: false,
                                  isIncoming: false,
                                  recipientName: viewModel.contact?.displayName)
    } else {
      memoContainerView.isHidden = true
    }
  }

}
