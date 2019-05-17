//
//  ConfirmPaymentViewController.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import CNBitcoinKit
import PhoneNumberKit

protocol ConfirmPaymentViewControllerDelegate: ViewControllerDismissable {
  func confirmPaymentViewControllerDidLoad(_ viewController: UIViewController)
  func viewControllerDidConfirmPayment(
    _ viewController: UIViewController,
    transactionData: CNBTransactionData,
    rates: ExchangeRates,
    outgoingTransactionData: OutgoingTransactionData
  )
  func viewControllerDidConfirmInvite(_ viewController: UIViewController, outgoingInvitationDTO: OutgoingInvitationDTO)
}

typealias BitcoinUSDPair = (btcAmount: NSDecimalNumber, usdAmount: NSDecimalNumber)

class ConfirmPaymentViewController: PresentableViewController, StoryboardInitializable {

  enum Kind {
    case invite(ConfirmPaymentInviteViewModel)
    case payment(ConfirmPaymentViewModel)
  }

  var kind: Kind?

  lazy private var confirmLongPressGestureRecognizer: UILongPressGestureRecognizer =
    UILongPressGestureRecognizer(target: self, action: #selector(confirmButtonDidConfirm))

  private var feedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

  let rateManager = ExchangeRateManager()

  @IBOutlet var closeButton: UIButton!
  @IBOutlet var confirmButton: ConfirmPaymentButton!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var primaryCurrencyLabel: UILabel!
  @IBOutlet var secondaryCurrencyLabel: UILabel!
  @IBOutlet var networkFeeLabel: UILabel!
  @IBOutlet var contactLabel: UILabel!
  @IBOutlet var primaryAddressLabel: UILabel!
  @IBOutlet var memoContainerView: ConfirmPaymentMemoView!
  @IBOutlet var secondaryAddressLabel: UILabel!
  @IBOutlet var tapAndHoldLabel: UILabel!

  var coordinationDelegate: ConfirmPaymentViewControllerDelegate? {
    return generalCoordinationDelegate as? ConfirmPaymentViewControllerDelegate
  }

  private func setupViews() {
    titleLabel.font = Theme.Font.onboardingSubtitle.font
    titleLabel.textColor = Theme.Color.darkBlueText.color

    primaryCurrencyLabel.textAlignment = .center
    primaryCurrencyLabel.textColor = Theme.Color.lightBlueTint.color
    primaryCurrencyLabel.font = Theme.Font.requestPayPrimaryCurrency.font

    secondaryCurrencyLabel.textAlignment = .center
    secondaryCurrencyLabel.textColor = Theme.Color.grayText.color
    secondaryCurrencyLabel.font = Theme.Font.requestPaySecondaryCurrency.font

    networkFeeLabel.textAlignment = .center
    networkFeeLabel.font = Theme.Font.sendPaymentNetworkFee.font
    networkFeeLabel.textColor = Theme.Color.sendPaymentNetworkFee.color

    contactLabel.backgroundColor = UIColor.clear
    contactLabel.font = Theme.Font.sendingAmountTo.font
    contactLabel.adjustsFontSizeToFitWidth = true

    primaryAddressLabel.backgroundColor = UIColor.clear
    primaryAddressLabel.font = Theme.Font.sendingAmountToAddress.font
    primaryAddressLabel.adjustsFontSizeToFitWidth = true

    memoContainerView.isHidden = true

    secondaryAddressLabel.textAlignment = .center
    secondaryAddressLabel.textColor = Theme.Color.grayText.color
    secondaryAddressLabel.font = Theme.Font.confirmPaymentSecondaryAddress.font

    tapAndHoldLabel.textColor = Theme.Color.darkGray.color
    tapAndHoldLabel.font = Theme.Font.tapReminderTitle.font
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

    let feeConverter = CurrencyConverter(rates: viewModel.rates,
                                         fromAmount: NSDecimalNumber(integerAmount: viewModel.fee, currency: .BTC),
                                         fromCurrency: .BTC,
                                         toCurrency: .USD)

    let btcFee = String(describing: feeConverter.amount(forCurrency: .BTC) ?? 0)
    let fiatFee = feeConverter.amountStringWithSymbol(forCurrency: .USD) ?? ""
    networkFeeLabel.text = "Network Fee \(btcFee) (\(fiatFee))"
  }

  private func updateRecipient(with viewModel: ConfirmPaymentViewModelType) {
    guard let contact = viewModel.contact else { return }
    var displayIdentity = ""
    switch contact.identityType {
    case .phone:
      guard let phoneContact = contact as? PhoneContactType else { return }
      let formatter = CKPhoneNumberFormatter(kit: PhoneNumberKit(), format: .international)
      displayIdentity = (try? formatter.string(from: phoneContact.globalPhoneNumber)) ?? ""
    case .twitter:
      displayIdentity = contact.displayIdentity
    }

    // Hide address labels by default, unhide as needed
    // Contact label is always shown, set text to nil to hide
    primaryAddressLabel.isHidden = true
    secondaryAddressLabel.isHidden = true

    // Set default contact and address label values
    contactLabel.text = viewModel.contact?.displayName
    primaryAddressLabel.text = viewModel.address
    secondaryAddressLabel.text = viewModel.address

    // May refer to either an actual contact or a manually entered phone number
    if let contact = viewModel.contact {
      switch contact.kind {
      case .generic:
        contactLabel.text = displayIdentity
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
    } else {
      // btc address
      primaryAddressLabel.isHidden = false
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
        confirmInvite(with: viewModel)
      case .payment(let viewModel):
        confirmPayment(with: viewModel)
      }
    }

    confirmButton.reset()
  }

  private func confirmPayment(with viewModel: ConfirmPaymentViewModel) {
    coordinationDelegate?.viewControllerDidConfirmPayment(
      self,
      transactionData: viewModel.transactionData,
      rates: viewModel.rates,
      outgoingTransactionData: viewModel.outgoingTransactionData
    )
  }

  private func confirmInvite(with viewModel: ConfirmPaymentInviteViewModel) {
    guard let contact = viewModel.contact, let btcAmount = viewModel.btcAmount else { return }

    let converter = CurrencyConverter(rates: viewModel.rates,
                                      fromAmount: btcAmount,
                                      fromCurrency: .BTC,
                                      toCurrency: .USD)

    let pair = (btcAmount: btcAmount, usdAmount: converter.amount(forCurrency: .USD) ?? NSDecimalNumber(decimal: 0.0))
    let outgoingInvitationDTO = OutgoingInvitationDTO(contact: contact,
                                                      btcPair: pair,
                                                      fee: viewModel.fee,
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
