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
  func viewControllerDidConfirmPayment(
    _ viewController: UIViewController,
    transactionData: CNBTransactionData,
    rates: ExchangeRates,
    outgoingTransactionData: OutgoingTransactionData
  )
  func viewControllerDidConfirmInvite(_ viewController: UIViewController, outgoingInvitationDTO: OutgoingInvitationDTO)
  func viewControllerRequestedShowFeeTooExpensiveAlert(_ viewController: UIViewController)
}

typealias BitcoinUSDPair = (btcAmount: NSDecimalNumber, usdAmount: NSDecimalNumber)

class ConfirmPaymentViewController: PresentableViewController, StoryboardInitializable {

  static func newInstance(kind: Kind,
                          feeModel: ConfirmTransactionFeeModel,
                          delegate: ConfirmPaymentViewControllerDelegate) -> ConfirmPaymentViewController {
    let vc = ConfirmPaymentViewController.makeFromStoryboard()
    vc.generalCoordinationDelegate = delegate
    vc.kind = kind
    vc.feeModel = feeModel
    switch kind {
    case .invite(let vm):
      vc.exchangeRates = vm.rates
    case .payment(let vm):
      vc.exchangeRates = vm.rates
    }

    return vc
  }

  enum Kind {
    case invite(ConfirmPaymentInviteViewModel)
    case payment(ConfirmPaymentViewModel)
  }

  var kind: Kind?
  var feeModel: ConfirmTransactionFeeModel!
  var exchangeRates: ExchangeRates!

  lazy private var confirmLongPressGestureRecognizer: UILongPressGestureRecognizer =
    UILongPressGestureRecognizer(target: self, action: #selector(confirmButtonDidConfirm))

  private var feedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

  @IBOutlet var closeButton: UIButton!
  @IBOutlet var confirmButton: ConfirmPaymentButton!
  @IBOutlet var titleLabel: UILabel!
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
      } else {
        coordinationDelegate?.viewControllerRequestedShowFeeTooExpensiveAlert(self)
      }

      self.updateFees(with: self.feeModel, rates: self.exchangeRates)
    default:
      break
    }
  }

  private func setupViews() {
    titleLabel.font = .regular(15)
    titleLabel.textColor = .darkBlueText

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

  private func updateView(with viewModel: ConfirmPaymentViewModelType) {
    updateAmounts(with: viewModel)
    updateRecipient(with: viewModel)
    updateMemoView(with: viewModel)
  }

  private func updateAmounts(with viewModel: ConfirmPaymentViewModelType) {
    let amounts = viewModel.amountLabels(withRates: viewModel.rates, withSymbols: true)
    primaryCurrencyLabel.text = amounts.primary
    secondaryCurrencyLabel.attributedText = amounts.secondary

    updateFees(with: self.feeModel, rates: viewModel.rates)

  }

  private func updateFees(with feeModel: ConfirmTransactionFeeModel, rates: ExchangeRates) {

    switch feeModel {
    case .adjustable(let vm):
      adjustableFeesContainer.isHidden = false
      adjustableFeesControl.selectedSegmentIndex = vm.selectedTypeIndex
      for (i, model) in vm.segmentModels.enumerated() {
        adjustableFeesControl.setTitle(model.title, forSegmentAt: i)
      }

      adjustableFeesLabel.attributedText = vm.attributedWaitTimeDescription

    case .required, .standard:
      adjustableFeesContainer.isHidden = true
    }

    let feeDecimalAmount = NSDecimalNumber(integerAmount: feeModel.feeAmount, currency: .BTC)
    let feeConverter = CurrencyConverter(rates: rates,
                                         fromAmount: feeDecimalAmount,
                                         fromCurrency: .BTC,
                                         toCurrency: .USD)

    let btcFee = String(describing: feeConverter.amount(forCurrency: .BTC) ?? 0)
    let fiatFee = feeConverter.amountStringWithSymbol(forCurrency: .USD) ?? ""
    networkFeeLabel.text = "Network Fee \(btcFee) (\(fiatFee))"
  }

  private func updateRecipient(with viewModel: ConfirmPaymentViewModelType) {
    // Hide address labels by default, unhide as needed
    // Contact label is always shown, set text to nil to hide
    primaryAddressLabel.isHidden = true
    secondaryAddressLabel.isHidden = true

    // Set default contact and address label values
    contactLabel.text = viewModel.contact?.displayName
    primaryAddressLabel.text = viewModel.address
    secondaryAddressLabel.text = viewModel.address

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

  private func updateMemoView(with viewModel: ConfirmPaymentViewModelType) {
    if let payload = viewModel.sharedPayloadDTO, let memo = payload.memo {
      memoContainerView.isHidden = false

      memoContainerView.configure(memo: memo,
                                  isShared: payload.shouldShare,
                                  isSent: false,
                                  isIncoming: false,
                                  recipientName: viewModel.contact?.displayName)
    } else {
      memoContainerView.isHidden = true
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    feedbackGenerator.prepare()
    confirmLongPressGestureRecognizer.allowableMovement = 1000
    confirmLongPressGestureRecognizer.minimumPressDuration = confirmButton.secondsToConfirm
    confirmButton.addGestureRecognizer(confirmLongPressGestureRecognizer)
    setupViews()

    coordinationDelegate?.confirmPaymentViewControllerDidLoad(self)

    guard let kind = kind else { return }
    switch kind {
    case .invite(let viewModel):
      updateView(with: viewModel)
    case .payment(let viewModel):
      updateView(with: viewModel)
    }
  }

  @objc func confirmButtonDidConfirm() {
    guard let kind = kind else { return }

    if confirmLongPressGestureRecognizer.state == .began {
      switch kind {
      case .invite(let viewModel):
        confirmInvite(with: viewModel, feeModel: self.feeModel)
      case .payment(let viewModel):
        confirmPayment(with: viewModel, feeModel: self.feeModel)
      }
    }

    confirmButton.reset()
  }

  private func confirmPayment(with viewModel: ConfirmPaymentViewModel,
                              feeModel: ConfirmTransactionFeeModel) {
    var feeAdjustedOutgoingTxData = viewModel.outgoingTransactionData
    feeAdjustedOutgoingTxData.amount = Int(feeModel.transactionData.amount)
    feeAdjustedOutgoingTxData.feeAmount = Int(feeModel.transactionData.feeAmount)

    coordinationDelegate?.viewControllerDidConfirmPayment(
      self,
      transactionData: feeModel.transactionData,
      rates: viewModel.rates,
      outgoingTransactionData: feeAdjustedOutgoingTxData
    )
  }

  private func confirmInvite(with viewModel: ConfirmPaymentInviteViewModel,
                             feeModel: ConfirmTransactionFeeModel) {
    guard let contact = viewModel.contact, let btcAmount = viewModel.btcAmount else { return }

    let converter = CurrencyConverter(rates: viewModel.rates,
                                      fromAmount: btcAmount,
                                      fromCurrency: .BTC,
                                      toCurrency: .USD)

    let pair = (btcAmount: btcAmount, usdAmount: converter.amount(forCurrency: .USD) ?? NSDecimalNumber(decimal: 0.0))
    let outgoingInvitationDTO = OutgoingInvitationDTO(contact: contact,
                                                      btcPair: pair,
                                                      fee: feeModel.feeAmount,
                                                      sharedPayloadDTO: viewModel.sharedPayloadDTO)
    coordinationDelegate?.viewControllerDidConfirmInvite(self, outgoingInvitationDTO: outgoingInvitationDTO)
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
}
