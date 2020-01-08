//
//  ConfirmPaymentViewController.swift
//  DropBit
//
//  Created by Mitchell on 4/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol ConfirmPaymentViewControllerDelegate: ViewControllerDismissable, AllPaymentSendingDelegate {
  func confirmPaymentViewControllerDidLoad(_ viewController: UIViewController)

  func viewControllerDidConfirmInvite(_ viewController: UIViewController,
                                      outgoingInvitationDTO: OutgoingInvitationDTO,
                                      walletTxType: WalletTransactionType)

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
    vc.delegate = delegate
    return vc
  }

  enum TransactionType {
    case invite, payment
  }

  private var transactionType: TransactionType = .payment
  private var viewModel: BaseConfirmPaymentViewModel!
  private var feeModel: ConfirmTransactionFeeModel!

  @IBOutlet var walletTransactionTypeButton: CompactActionButton!
  @IBOutlet var closeButton: UIButton!
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
  @IBOutlet var avatarBackgroundView: UIView!
  @IBOutlet var avatarImageView: UIImageView!
  @IBOutlet var confirmView: ConfirmView!
  @IBOutlet var topStackViewTopConstraint: NSLayoutConstraint!

  private(set) weak var delegate: ConfirmPaymentViewControllerDelegate!

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
        delegate.viewControllerRequestedShowFeeTooExpensiveAlert(self)
      }

      self.updateFeeViews()
      self.updateAmountViews()
    default:
      break
    }
  }

  @IBAction func closeButtonWasTouched() {
    delegate.viewControllerDidSelectClose(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()

    if let viewModel = viewModel {
      switch viewModel.walletTransactionType {
      case .onChain:    confirmView.confirmButton.configure(with: .onChain, delegate: self)
      case .lightning:  confirmView.confirmButton.configure(with: .lightning, delegate: self)
      }
    }

    delegate.confirmPaymentViewControllerDidLoad(self)

    updateViewWithModel()
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
    feeAdjustedOutgoingTxData.amount = txData.amount
    feeAdjustedOutgoingTxData.feeAmount = txData.feeAmount

    delegate.viewControllerDidConfirmOnChainPayment(
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
    delegate.viewControllerDidConfirmLightningPayment(self, inputs: inputs, receiver: viewModel.contact)
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
                                                      walletTxType: viewModel.walletTransactionType,
                                                      sharedPayloadDTO: viewModel.sharedPayloadDTO)
    delegate.viewControllerDidConfirmInvite(self,
                                            outgoingInvitationDTO: outgoingInvitationDTO,
                                            walletTxType: viewModel.walletTransactionType)
  }

}

// MARK: - View Configuration

extension ConfirmPaymentViewController {

  fileprivate func setupViews() {
    switch UIScreen.main.relativeSize {
    case .short: topStackViewTopConstraint.constant = 18
    case .medium: topStackViewTopConstraint.constant = 24
    case .tall: topStackViewTopConstraint.constant = 32
    }
    view.layoutIfNeeded()

    primaryCurrencyLabel.textAlignment = .center
    primaryCurrencyLabel.textColor = .lightBlueTint
    primaryCurrencyLabel.font = .regular(viewModel.primaryAmountFontSize)

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

    memoContainerView.isHidden = true

    secondaryAddressLabel.textAlignment = .center
    secondaryAddressLabel.textColor = .darkGrayText
    secondaryAddressLabel.font = .regular(13)

    if let viewModel = viewModel {
      switch viewModel.walletTransactionType {
      case .lightning:
        networkFeeLabel.isHidden = true
        primaryAddressLabel.lineBreakMode = .byTruncatingMiddle
        walletTransactionTypeButton.style = .lightning(rounded: true)
        walletTransactionTypeButton.setAttributedTitle(NSAttributedString.lightningSelectedButtonTitle, for: .normal)
      case .onChain:
        primaryAddressLabel.adjustsFontSizeToFitWidth = true
        walletTransactionTypeButton.style = .bitcoin(rounded: true)
        walletTransactionTypeButton.setAttributedTitle(NSAttributedString.bitcoinSelectedButton, for: .normal)
      }
    }

    adjustableFeesControl.tintColor = .primaryActionButton
    if #available(iOS 13, *) {
      adjustableFeesControl.selectedSegmentTintColor = .primaryActionButton
    }
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
    let labels = viewModel.dualAmountLabels(walletTxType: viewModel.walletTransactionType)
    primaryCurrencyLabel.attributedText = labels.primary
    secondaryCurrencyLabel.attributedText = labels.secondary
  }

  fileprivate func updateFeeViews() {
    guard let feeModel = feeModel else { return }

    switch feeModel {
    case .adjustable(let vm):
      adjustableFeesContainer.isHidden = !vm.isAdjustable
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
    let fiatFeeAmount = feeConverter.amount(forCurrency: .USD)
    let fiatFeeString = FiatFormatter(currency: .USD, withSymbol: true).string(fromDecimal: fiatFeeAmount ?? .zero) ?? ""
    networkFeeLabel.text = "Network Fee \(btcFee) (\(fiatFeeString))"
  }

  fileprivate func updateRecipientViews() {
    // Hide address labels by default, unhide as needed
    // Contact label is always shown, set text to nil to hide
    primaryAddressLabel.isHidden = true
    secondaryAddressLabel.isHidden = true

    // Set default contact and address label values
    contactLabel.text = viewModel.contact?.displayName
    primaryAddressLabel.text = viewModel.paymentTarget
    secondaryAddressLabel.text = viewModel.paymentTarget

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

      let config = ConfirmPaymentMemoViewConfig(memo: memo, isShared: viewModel.shouldShareMemo,
                                                isSent: false, isIncoming: false,
                                                recipientName: viewModel.contact?.displayName)
      memoContainerView.configure(with: config)
    } else {
      memoContainerView.isHidden = true
    }
  }

}

extension ConfirmPaymentViewController: LongPressConfirmButtonDelegate {

  func confirmationButtonDidConfirm(_ button: LongPressConfirmButton) {
    switch transactionType {
    case .invite:
      guard let inviteVM = viewModel as? ConfirmPaymentInviteViewModel else { return }
      self.confirmInvite(with: inviteVM, feeModel: feeModel)
    case .payment:
      routeConfirmedPayment(for: viewModel, feeModel: self.feeModel)
    }
  }

}
