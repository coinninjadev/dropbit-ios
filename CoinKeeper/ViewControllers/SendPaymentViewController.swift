//
//  SendPaymentViewController.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 4/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import Contacts
import enum Result.Result
import PhoneNumberKit
import CNBitcoinKit
import PromiseKit

typealias SendPaymentViewControllerCoordinator = SendPaymentViewControllerDelegate &
  CurrencyValueDataSourceType & BalanceDataSource & PaymentRequestResolver & URLOpener & ViewControllerDismissable

// swiftlint:disable file_length
class SendPaymentViewController: PresentableViewController,
  StoryboardInitializable,
  PaymentAmountValidatable,
  PhoneNumberEntryViewDisplayable,
  ValidatorAlertDisplayable,
  CurrencySwappableAmountEditor {

  var viewModel: SendPaymentViewModel!
  var alertManager: AlertManagerType?
  let rateManager = ExchangeRateManager()
  var hashingManager = HashingManager()

  var editAmountViewModel: CurrencySwappableEditAmountViewModel {
    return viewModel
  }

  /// The presenter of SendPaymentViewController can set this property to provide a recipient.
  /// It will be parsed and used to update the viewModel and view when ready.
  var recipientDescriptionToLoad: String?

  var countryCodeSearchView: CountryCodeSearchView?
  let countryCodeDataSource = CountryCodePickerDataSource()

  var coordinationDelegate: SendPaymentViewControllerCoordinator? {
    return generalCoordinationDelegate as? SendPaymentViewControllerCoordinator
  }

  var currencyValueManager: CurrencyValueDataSourceType? {
    return coordinationDelegate
  }

  var balanceDataSource: BalanceDataSource? {
    return coordinationDelegate
  }

  // MARK: - Outlets and Actions

  @IBOutlet var closeButton: UIButton!

  @IBOutlet var editAmountView: CurrencySwappableEditAmountView!
  @IBOutlet var phoneNumberEntryView: PhoneNumberEntryView!
  @IBOutlet var walletToggleView: WalletToggleView!

  @IBOutlet var addressScanButtonContainerView: UIView!
  @IBOutlet var bitcoinAddressButton: UIButton!
  @IBOutlet var scanButton: UIButton!

  @IBOutlet var recipientDisplayNameLabel: UILabel!
  @IBOutlet var recipientDisplayNumberLabel: UILabel!

  @IBOutlet var contactsButton: CompactActionButton!
  @IBOutlet var twitterButton: CompactActionButton!
  @IBOutlet var pasteButton: CompactActionButton!

  @IBOutlet var nextButton: PrimaryActionButton!
  @IBOutlet var memoContainerView: SendPaymentMemoView!
  @IBOutlet var sendMaxButton: LightBorderedButton!

  @IBAction func performClose() {
    coordinationDelegate?.sendPaymentViewControllerWillDismiss(self)
  }

  @IBAction func performPaste() {
    coordinationDelegate?.viewControllerDidSelectPaste(self)
    if let text = UIPasteboard.general.string {
      applyRecipient(inText: text)
    }
  }

  @IBAction func performContacts() {
    coordinationDelegate?.viewControllerDidPressContacts(self)
  }

  @IBAction func performTwitter() {
    coordinationDelegate?.viewControllerDidPressTwitter(self)
  }

  @IBAction func performScan() {
    let converter = viewModel.generateCurrencyConverter()
    coordinationDelegate?.viewControllerDidPressScan(self,
                                                     btcAmount: converter.btcAmount,
                                                     primaryCurrency: primaryCurrency)
  }

  @IBAction func performNext() {
    do {
      try validateAmount()
      try validateAndSendPayment()
    } catch {
      showValidatorAlert(for: error, title: "Invalid Transaction")
    }
  }

  @IBAction func performSendMax() {
    let tempAddress = ""
    self.coordinationDelegate?.latestFees()
      .compactMap { self.coordinationDelegate?.usableFeeRate(from: $0) }
      .then { feeRate -> Promise<CNBTransactionData> in
        guard let delegate = self.coordinationDelegate else { fatalError("coordinationDelegate is required") }
        return delegate.viewController(self, sendMaxFundsTo: tempAddress, feeRate: feeRate)
      }
      .done {txData in
        self.viewModel.sendMax(with: txData)
        self.refreshBothAmounts()
        self.sendMaxButton.isHidden = true
      }
      .catch { _ in
        let action = AlertActionConfiguration.init(title: "OK", style: .default, action: nil)
        let alertViewModel = AlertControllerViewModel(
          title: "Insufficient Funds",
          description: "There are not enough funds to cover the transaction and network fee.",
          image: nil,
          style: .alert,
          actions: [action]
        )
        self.coordinationDelegate?.viewControllerDidRequestAlert(self, viewModel: alertViewModel)
    }
  }

  @IBAction func performStartPhoneEntry() {
    showPhoneEntryView(with: "")
    phoneNumberEntryView.textField?.becomeFirstResponder()
  }

  /// Each button should connect to this IBAction. This prevents automatically
  /// calling textFieldDidBeginEditing() if/when this view reappears.
  @IBAction func dismissKeyboard() {
    editAmountView.primaryAmountTextField.resignFirstResponder()
    phoneNumberEntryView.textField.resignFirstResponder()
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .sendPayment(.page)),
      (memoContainerView.memoLabel, .sendPayment(.memoLabel))
    ]
  }

  static func newInstance(delegate: SendPaymentViewControllerDelegate, viewModel: SendPaymentViewModel) -> SendPaymentViewController {
    let vc = SendPaymentViewController.makeFromStoryboard()
    vc.generalCoordinationDelegate = delegate
    vc.viewModel = viewModel
    vc.viewModel.delegate = vc
    return vc
  }

  // MARK: - View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    setupMenuController()
    registerForRateUpdates()
    updateRatesAndView()
    setupKeyboardDoneButton(for: [editAmountView.primaryAmountTextField,
                                  phoneNumberEntryView.textField],
                            action: #selector(doneButtonWasPressed))
    setupCurrencySwappableEditAmountView()
    setupLabels()
    setupButtons()
    setupStyle()
    formatAddressScanView()
    setupPhoneNumberEntryView(textFieldEnabled: true)
    formatPhoneNumberEntryView()
    memoContainerView.delegate = self
    let sharedMemoAllowed = coordinationDelegate?.viewControllerShouldInitiallyAllowMemoSharing(self) ?? true
    viewModel.sharedMemoAllowed = sharedMemoAllowed
    memoContainerView.configure(memo: nil, isShared: sharedMemoAllowed)
    coordinationDelegate?.sendPaymentViewControllerDidLoad(self)
    walletToggleView.delegate = self

    if viewModel.fromAmount == .zero && recipientDescriptionToLoad == nil {
      editAmountView.primaryAmountTextField.becomeFirstResponder()
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if let recipientDescription = self.recipientDescriptionToLoad {
      self.applyRecipient(inText: recipientDescription)
      self.recipientDescriptionToLoad = nil
    } else {
      updateViewWithModel()
    }
  }

  @objc func doneButtonWasPressed() {
    dismissKeyboard()
  }

}

// MARK: - View Configuration

extension SendPaymentViewController {

  fileprivate func setupLabels() {
    recipientDisplayNameLabel.font = .regular(26)
    recipientDisplayNumberLabel.font = .regular(20)
  }

  fileprivate func setupStyle() {
    switch viewModel.type {
    case .lightning:
      contactsButton.style = .lightning(true)
      twitterButton.style = .lightning(true)
      pasteButton.style = .lightning(true)
      nextButton.style = .lightning(true)
      walletToggleView.selectLightningButton()
    case .onChain:
      contactsButton.style = .bitcoin(true)
      twitterButton.style = .bitcoin(true)
      pasteButton.style = .bitcoin(true)
      nextButton.style = .bitcoin(true)
      walletToggleView.selectBitcoinButton()
    }
  }

  fileprivate func setupButtons() {
    let textColor = UIColor.whiteText
    let font = UIFont.compactButtonTitle
    let contactsTitle = NSAttributedString(imageName: "contactsIcon",
                                           imageSize: CGSize(width: 9, height: 14),
                                           title: "CONTACTS",
                                           sharedColor: textColor,
                                           font: font)
    contactsButton.setAttributedTitle(contactsTitle, for: .normal)

    let twitterTitle = NSAttributedString(imageName: "twitterBird",
                                          imageSize: CGSize(width: 20, height: 16),
                                          title: "TWITTER",
                                          sharedColor: textColor,
                                          font: font)
    twitterButton.setAttributedTitle(twitterTitle, for: .normal)

    let pasteTitle = NSAttributedString(imageName: "pasteIcon",
                                        imageSize: CGSize(width: 16, height: 14),
                                        title: "PASTE",
                                        sharedColor: textColor,
                                        font: font)
    pasteButton.setAttributedTitle(pasteTitle, for: .normal)
  }

  fileprivate func formatAddressScanView() {
    addressScanButtonContainerView.applyCornerRadius(4)
    addressScanButtonContainerView.layer.borderColor = UIColor.mediumGrayBorder.cgColor
    addressScanButtonContainerView.layer.borderWidth = 1.0

    bitcoinAddressButton.titleLabel?.font = .medium(14)
    bitcoinAddressButton.setTitleColor(.darkGrayText, for: .normal)
    bitcoinAddressButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

    scanButton.backgroundColor = .mediumGrayBackground
  }

  fileprivate func formatPhoneNumberEntryView() {
    guard let entryView = phoneNumberEntryView else { return }
    entryView.backgroundColor = UIColor.clear
    entryView.layer.borderColor = UIColor.mediumGrayBorder.cgColor
    entryView.textField.delegate = self
    entryView.textField.backgroundColor = UIColor.clear
    entryView.textField.autocorrectionType = .no
    entryView.textField.font = .medium(14)
    entryView.textField.textColor = .darkBlueText
    entryView.textField.adjustsFontSizeToFitWidth = true
    entryView.textField.keyboardType = .numberPad
    entryView.textField.textAlignment = .center
    entryView.textField.isUserInteractionEnabled = true

    updateRecipientContainerContentType(forRecipient: viewModel.paymentRecipient)
  }

  fileprivate func setupMenuController() {
    let controller = UIMenuController.shared
    let pasteItem = UIMenuItem(title: "Paste", action: #selector(performPaste))
    controller.menuItems = [pasteItem]
    controller.update()
  }

  func updateViewWithModel() {
    if editAmountView.primaryAmountTextField.isFirstResponder {
      refreshSecondaryAmount()
    } else {
      refreshBothAmounts()
    }

    if viewModel.btcAmount != .zero {
      sendMaxButton.isHidden = true
    }

    phoneNumberEntryView.textField.text = ""

    self.recipientDisplayNameLabel.text = viewModel.contact?.displayName
    self.recipientDisplayNumberLabel.text = viewModel.contact?.displayIdentity

    let displayStyle = viewModel.displayStyle(for: viewModel.paymentRecipient)
    switch displayStyle {
    case .textField:
      phoneNumberEntryView.alpha = 1.0
      recipientDisplayNameLabel.alpha = 0.0
      recipientDisplayNumberLabel.alpha = 0.0
      recipientDisplayNameLabel.text = ""
      recipientDisplayNumberLabel.text = ""

    case .label:
      phoneNumberEntryView.alpha = 0.0
      recipientDisplayNameLabel.alpha = 1.0
      recipientDisplayNumberLabel.alpha = 1.0
      recipientDisplayNameLabel.text = viewModel.displayRecipientName()
      recipientDisplayNumberLabel.text = viewModel.displayRecipientIdentity()
    }

    updateMemoContainer()
  }

  func updateMemoContainer() {
    self.memoContainerView.configure(memo: viewModel.memo, isShared: viewModel.sharedMemoDesired)
    self.memoContainerView.bottomBackgroundView.isHidden = !viewModel.shouldShowSharedMemoBox

    UIView.animate(withDuration: 0.2, animations: { [weak self] in
      self?.view.layoutIfNeeded()
    })
  }

}

// MARK: - Recipients

extension SendPaymentViewController {

  func applyRecipient(inText text: String) {
    do {
      let recipient = try viewModel.recipientParser.findSingleRecipient(inText: text, ofTypes: [.bitcoinURL, .phoneNumber])
      editAmountView.primaryAmountTextField.resignFirstResponder()
      updateViewModel(withParsedRecipient: recipient)

    } catch {
      setPaymentRecipient(nil)
      coordinationDelegate?.viewControllerDidAttemptInvalidDestination(self, error: error)
    }

    updateViewWithModel()

    phoneNumberEntryView.resignFirstResponder()
  }

  func updateViewModel(withParsedRecipient parsedRecipient: CKParsedRecipient) {
    switch parsedRecipient {
    case .phoneNumber:
      setPaymentRecipient(PaymentRecipient(parsedRecipient: parsedRecipient))
    case .bitcoinURL(let bitcoinURL):
      if let paymentRequest = bitcoinURL.components.paymentRequest {
        self.fetchViewModelAndUpdate(forPaymentRequest: paymentRequest)
      } else {
        setPaymentRecipient(PaymentRecipient(parsedRecipient: parsedRecipient))
        if let amount = bitcoinURL.components.amount {
          self.viewModel.setBTCAmountAsPrimary(amount)
        }
      }
    }
  }

  private func fetchViewModelAndUpdate(forPaymentRequest url: URL) {
    self.alertManager?.showActivityHUD(withStatus: nil)
    self.coordinationDelegate?.resolveMerchantPaymentRequest(withURL: url) { result in
      let errorTitle = "Payment Request Error"
      switch result {
      case .success(let response):
        guard let fetchedModel = SendPaymentViewModel(response: response,
                                                      walletType: self.viewModel.type,
                                                      exchangeRates: self.viewModel.exchangeRates,
                                                      fiatCurrency: self.viewModel.fiatCurrency),
          let fetchedAddress = fetchedModel.address else {
            self.showValidatorAlert(for: MerchantPaymentRequestError.missingOutput, title: errorTitle)
            return
        }

        self.viewModel = fetchedModel
        self.setPaymentRecipient(PaymentRecipient.btcAddress(fetchedAddress))
        self.viewModel.setBTCAmountAsPrimary(fetchedModel.btcAmount)

        self.alertManager?.hideActivityHUD(withDelay: nil) {
          self.updateViewWithModel()
        }

      case .failure(let error):
        self.alertManager?.hideActivityHUD(withDelay: nil) {
          let viewModel = AlertControllerViewModel(title: "", description: error.localizedDescription)
          self.coordinationDelegate?.viewControllerDidRequestAlert(self, viewModel: viewModel)
        }
      }
    }
  }

  func setPaymentRecipient(_ paymentRecipient: PaymentRecipient?) {
    self.viewModel.paymentRecipient = paymentRecipient
    updateRecipientContainerContentType(forRecipient: paymentRecipient)
  }

  func updateRecipientContainerContentType(forRecipient paymentRecipient: PaymentRecipient?) {
    DispatchQueue.main.async {
      guard let recipient = paymentRecipient else {
        self.showBitcoinAddressRecipient(with: "To: BTC Address or phone number")
        return
      }
      switch recipient {
      case .btcAddress(let btcAddress):
        self.showBitcoinAddressRecipient(with: btcAddress)
      case .phoneNumber(let contact):
        self.coordinationDelegate?.viewController(self, checkForContactFromGenericContact: contact) { possibleValidatedContact in
          if let validatedContact = possibleValidatedContact {
            self.viewModel.paymentRecipient = PaymentRecipient.contact(validatedContact)
            self.updateViewWithModel()
            self.hideRecipientInputViews()
          } else {
            self.showPhoneEntryView(with: contact)
          }
        }
      case .contact:
        self.hideRecipientInputViews()
      case .twitterContact(let twitterContact):
        self.coordinationDelegate?.viewController(self, checkForVerifiedTwitterContact: twitterContact)
          .done { _ in
            self.viewModel.paymentRecipient = paymentRecipient
            self.updateViewWithModel()
            self.hideRecipientInputViews()
          }
          .catch { (error: Error) in
            if let userProviderError = error as? UserProviderError {
              // user query returned no known verification status
              log.error(userProviderError, message: "no verification status found")
            }
          }
      }
    }
  }

  private func showBitcoinAddressRecipient(with title: String) {
    self.addressScanButtonContainerView.isHidden = false
    self.phoneNumberEntryView.isHidden = true
    self.bitcoinAddressButton.setTitle(title, for: .normal)
  }

  private func showPhoneEntryView(with title: String) {
    self.addressScanButtonContainerView.isHidden = true
    self.phoneNumberEntryView.isHidden = false
    self.phoneNumberEntryView.textField.text = title
  }

  private func showPhoneEntryView(with contact: GenericContact) {
    self.addressScanButtonContainerView.isHidden = true
    self.phoneNumberEntryView.isHidden = false

    let region = phoneNumberEntryView.selectedRegion
    let country = CKCountry(regionCode: region)
    let number = contact.globalPhoneNumber.nationalNumber

    self.phoneNumberEntryView.textField.update(withCountry: country, nationalNumber: number)
  }

  private func hideRecipientInputViews() {
    self.addressScanButtonContainerView.isHidden = true
    self.phoneNumberEntryView.isHidden = true
  }

}

extension SendPaymentViewController: SelectedValidContactDelegate {
  func update(withSelectedContact contact: ContactType) {
    setPaymentRecipient(.contact(contact))
    updateViewWithModel()
  }

  func update(withSelectedTwitterUser twitterUser: TwitterUser) {
    var contact = TwitterContact(twitterUser: twitterUser)
    coordinationDelegate?.viewController(self, checkingVerificationStatusFor: twitterUser.idStr)
      .done { (responses: [WalletAddressesQueryResponse]) in
        contact.kind = (responses.isEmpty) ? .invite : .registeredUser
        self.setPaymentRecipient(.twitterContact(contact))
        self.updateViewWithModel()
      }
      .catch { error in
        log.error(error, message: "failed to fetch verification status for \(twitterUser.idStr)")
    }
  }
}

// MARK: - Amounts and Currencies

extension SendPaymentViewController {

  var primaryCurrency: CurrencyCode {
    return viewModel.primaryCurrency
  }

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    self.updateEditAmountView(withRates: exchangeRateManager.exchangeRates)
  }

}

extension SendPaymentViewController: UITextFieldDelegate {

  func textFieldDidBeginEditing(_ textField: UITextField) {
    guard textField == phoneNumberEntryView.textField else { return }
    let defaultCountry = CKCountry(locale: .current)
    let phoneNumber = GlobalPhoneNumber(countryCode: defaultCountry.countryCode, nationalNumber: "")
    let contact = GenericContact(phoneNumber: phoneNumber, formatted: "")
    let recipient = PaymentRecipient.phoneNumber(contact)
    setPaymentRecipient(recipient)
    updateViewWithModel()
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    // Skip triggering changes/validation if textField is empty
    guard let text = textField.text, text.isNotEmpty,
      textField == phoneNumberEntryView.textField else {
      return
    }

    let currentNumber = phoneNumberEntryView.textField.currentGlobalNumber()
    guard currentNumber.nationalNumber.isNotEmpty else { return } //don't attempt parsing if only dismissing keypad or changing country

    do {
      let recipient = try viewModel.recipientParser.findSingleRecipient(inText: text, ofTypes: [.phoneNumber])
      switch recipient {
      case .bitcoinURL: updateViewModel(withParsedRecipient: recipient)
      case .phoneNumber(let globalPhoneNumber):
        let formattedPhoneNumber = try CKPhoneNumberFormatter(format: .international)
          .string(from: globalPhoneNumber)
        let contact = GenericContact(phoneNumber: globalPhoneNumber, formatted: formattedPhoneNumber)
        let recipient = PaymentRecipient.phoneNumber(contact)
        setPaymentRecipient(recipient)
      }
    } catch {
      self.coordinationDelegate?.showAlertForInvalidContactOrPhoneNumber(contactName: nil, displayNumber: text)
    }
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if let pasteboardText = UIPasteboard.general.string, pasteboardText.isNotEmpty, pasteboardText == string {
      applyRecipient(inText: pasteboardText)
    }

    if string.isNotEmpty {
      phoneNumberEntryView.textField.selected(digit: string)
    } else {
      phoneNumberEntryView.textField.selectedBack()
    }
    return false  // manage this manually
  }

  private func showInvalidPhoneNumberAlert() {
    let config = AlertActionConfiguration(title: "OK", style: .default, action: { [weak self] in
      self?.phoneNumberEntryView.textField.text = ""
    })
    guard let alert = self.alertManager?.alert(withTitle: "Error",
                                               description: "Invalid phone number. Please try again.",
                                               image: nil,
                                               style: .alert,
                                               actionConfigs: [config]) else { return }
    show(alert, sender: nil)
  }

}

extension SendPaymentViewController: CKPhoneNumberTextFieldDelegate {
  func textFieldReceivedValidMobileNumber(_ phoneNumber: GlobalPhoneNumber, textField: CKPhoneNumberTextField) {
    dismissKeyboard()
  }

  func textFieldReceivedInvalidMobileNumber(_ phoneNumber: GlobalPhoneNumber, textField: CKPhoneNumberTextField) {
    coordinationDelegate?.showAlertForInvalidContactOrPhoneNumber(contactName: nil, displayNumber: phoneNumber.asE164())
  }
}

extension SendPaymentViewController: SendPaymentMemoViewDelegate {

  func didTapMemoButton() {
    coordinationDelegate?.viewControllerDidSelectMemoButton(self, memo: viewModel.memo) { [weak self] memo in
      self?.viewModel.memo = memo
      self?.updateMemoContainer()
    }
  }

  func didTapShareButton() {
    viewModel.sharedMemoDesired = !viewModel.sharedMemoDesired
    self.updateMemoContainer()
  }

  func didTapSharedMemoTooltip() {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .sharedMemosTooltip) else { return }
    coordinationDelegate?.openURL(url, completionHandler: nil)
  }

}

// MARK: Validation

extension SendPaymentViewController {

  func validateAmount() throws {
    let ignoredOptions = viewModel.standardIgnoredOptions
    let amountValidator = createCurrencyAmountValidator(ignoring: ignoredOptions)

    let converter = viewModel.generateCurrencyConverter()
    try amountValidator.validate(value: converter)
  }

  private func validateInvitationMaximum(against btcAmount: NSDecimalNumber) throws {
    guard let recipient = viewModel.paymentRecipient,
      case let .contact(contact) = recipient,
      contact.kind == .invite
      else { return }

    let ignoredOptions = viewModel.invitationMaximumIgnoredOptions
    let validator = createCurrencyAmountValidator(ignoring: ignoredOptions)
    let converter = viewModel.generateCurrencyConverter(withBTCAmount: btcAmount)
    try validator.validate(value: converter)
  }

  private func validateAndSendPayment() throws {
    guard let recipient = viewModel.paymentRecipient else {
      throw BitcoinAddressValidatorError.isInvalidBitcoinAddress
    }
    switch recipient {
    case .contact(let contact):
      try validatePayment(toContact: contact)
    case .phoneNumber(let genericContact):
      try validatePayment(toContact: genericContact)
    case .btcAddress(let address):
      try validatePayment(toAddress: address)
    case .twitterContact(let contact):
      try validatePayment(toContact: contact)
    }
  }

  private func sharedAmountInfo() -> SharedPayloadAmountInfo {
    return SharedPayloadAmountInfo(fiatCurrency: .USD, fiatAmount: 1)
  }

  private func validatePayment(toAddress address: String) throws {
    let recipient = try viewModel.recipientParser.findSingleRecipient(inText: address, ofTypes: [.bitcoinURL])
    guard case let .bitcoinURL(url) = recipient, let address = url.components.address else {
      throw BitcoinAddressValidatorError.isInvalidBitcoinAddress
    }

    // This is still required here to pass along the local memo
    let sharedPayloadDTO = SharedPayloadDTO(addressPubKeyState: .none,
                                            sharingDesired: self.viewModel.sharedMemoDesired,
                                            memo: self.viewModel.memo,
                                            amountInfo: sharedAmountInfo())

    sendTransactionForConfirmation(with: viewModel.sendMaxTransactionData,
                                   address: address,
                                   contact: nil,
                                   sharedPayload: sharedPayloadDTO)
  }

  /// This evaluates the contact, some of it asynchronously, before sending
  private func validatePayment(toContact contact: ContactType) throws {
    let sharedPayload = SharedPayloadDTO(addressPubKeyState: .invite,
                                         sharingDesired: self.viewModel.sharedMemoDesired,
                                         memo: self.viewModel.memo,
                                         amountInfo: sharedAmountInfo())
    switch contact.kind {
    case .invite:
      try validateAmountAndBeginAddressNegotiation(for: contact, kind: .invite, sharedPayload: sharedPayload)
    case .registeredUser:
      validateRegisteredContact(contact, sharedPayload: sharedPayload)
    case .generic:
      validateGenericContact(contact, sharedPayload: sharedPayload)
    }
  }

  private func validateAmountAndBeginAddressNegotiation(for contact: ContactType, kind: ContactKind, sharedPayload: SharedPayloadDTO) throws {
    let btcAmount = viewModel.btcAmount

    var newContact = contact
    newContact.kind = kind
    switch contact.dropBitType {
    case .phone(let contact): self.setPaymentRecipient(.contact(contact))
    case .twitter(let contact): self.setPaymentRecipient(.twitterContact(contact))
    case .none: break
    }

    try validateInvitationMaximum(against: btcAmount)
    coordinationDelegate?.viewControllerDidBeginAddressNegotiation(self,
                                                                   btcAmount: btcAmount,
                                                                   primaryCurrency: primaryCurrency,
                                                                   contact: newContact,
                                                                   memo: self.viewModel.memo,
                                                                   walletType: self.viewModel.type,
                                                                   rates: self.rateManager.exchangeRates,
                                                                   memoIsShared: self.viewModel.sharedMemoDesired,
                                                                   sharedPayload: sharedPayload)
  }

  private func handleContactValidationError(_ error: Error) {
    self.showValidatorAlert(for: error, title: "")
  }

  private func validateRegisteredContact(_ contact: ContactType, sharedPayload: SharedPayloadDTO) {
    coordinationDelegate?.viewController(self, checkingVerificationStatusFor: contact.identityHash)
      .done { (responses: [WalletAddressesQueryResponse]) in
        if let addressResponse = responses.first(where: { $0.identityHash == contact.identityHash }) {
          var updatedPayload = sharedPayload
          updatedPayload.updatePubKeyState(with: addressResponse)
          self.sendTransactionForConfirmation(with: self.viewModel.sendMaxTransactionData,
                                              address: addressResponse.address,
                                              contact: contact,
                                              sharedPayload: updatedPayload)
        } else {
          // The contact has not backed up their words so our fetch didn't return an address, degrade to address negotiation
          do {
            try self.validateAmountAndBeginAddressNegotiation(for: contact, kind: .registeredUser, sharedPayload: sharedPayload)
          } catch {
            self.handleContactValidationError(error)
          }
        }
      }
      .catch { error in
        self.handleContactValidationError(error)
    }
  }

  private func validateGenericContact(_ contact: ContactType, sharedPayload: SharedPayloadDTO) {
    // Sending payment to generic contact (manually entered phone number) will first check if they have addresses on server
    coordinationDelegate?.viewControllerDidRequestVerificationCheck(self) { [weak self] in
      guard let localSelf = self,
        let delegate = localSelf.coordinationDelegate
        else { return }

      delegate.viewController(localSelf, checkingVerificationStatusFor: contact.identityHash)
        .done { (responses: [WalletAddressesQueryResponse]) in
          self?.handleGenericContactAddressCheckCompletion(forContact: contact, sharedPayload: sharedPayload, responses: responses)
        }
        .catch { error in
          self?.handleContactValidationError(error)
        }
    }
  }

  private func handleGenericContactAddressCheckCompletion(forContact contact: ContactType,
                                                          sharedPayload: SharedPayloadDTO,
                                                          responses: [WalletAddressesQueryResponse]) {
    var newContact = contact

    if let addressResponse = responses.first(where: { $0.identityHash == contact.identityHash }) {
      var updatedPayload = sharedPayload
      updatedPayload.updatePubKeyState(with: addressResponse)

      newContact.kind = .registeredUser
      sendTransactionForConfirmation(with: viewModel.sendMaxTransactionData,
                                     address: addressResponse.address,
                                     contact: newContact,
                                     sharedPayload: updatedPayload)
    } else {
      do {
        try validateAmountAndBeginAddressNegotiation(for: newContact, kind: .invite, sharedPayload: sharedPayload)
      } catch {
        self.handleContactValidationError(error)
      }
    }
  }

  private func sendTransactionForConfirmation(with data: CNBTransactionData?,
                                              address: String,
                                              contact: ContactType?,
                                              sharedPayload: SharedPayloadDTO) {
    let rates = rateManager.exchangeRates
    if let data = viewModel.sendMaxTransactionData {
      coordinationDelegate?.viewController(self,
                                           sendingMax: data,
                                           address: address,
                                           walletType: viewModel.type,
                                           contact: contact,
                                           rates: rates,
                                           sharedPayload: sharedPayload)
    } else {
      self.coordinationDelegate?.viewControllerDidSendPayment(self,
                                                              btcAmount: viewModel.btcAmount,
                                                              requiredFeeRate: viewModel.requiredFeeRate,
                                                              primaryCurrency: primaryCurrency,
                                                              address: address,
                                                              walletType: viewModel.type,
                                                              contact: contact,
                                                              rates: rates,
                                                              sharedPayload: sharedPayload)
    }

  }
}

extension SendPaymentViewController {
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    return (action == #selector(performPaste))
  }
}

extension SendPaymentViewController: WalletToggleViewDelegate {

  func bitcoinWalletButtonWasTouched() {
    viewModel.type = .onChain
    setupStyle()
  }

  func lightningWalletButtonWasTouched() {
    viewModel.type = .lightning
    setupStyle()
  }

}
