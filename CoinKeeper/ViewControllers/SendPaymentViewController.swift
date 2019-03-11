//
//  SendPaymentViewController.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 4/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import Contacts
import Result
import PhoneNumberKit

typealias SendPaymentViewControllerCoordinator = SendPaymentViewControllerDelegate &
  CurrencyValueDataSourceType & BalanceDataSource & PaymentRequestResolver & URLOpener & ViewControllerDismissable

// swiftlint:disable file_length
class SendPaymentViewController: PresentableViewController,
  StoryboardInitializable,
  ExchangeRateUpdateable,
  PaymentAmountValidatable,
  PhoneNumberEntryViewDisplayable,
ValidatorAlertDisplayable {

  var viewModel: SendPaymentViewModelType = SendPaymentViewModel(btcAmount: 0, primaryCurrency: .USD,
                                                                 parser: CKRecipientParser(kit: PhoneNumberKit()))
  var alertManager: AlertManagerType?
  let rateManager = ExchangeRateManager()
  let phoneNumberKit = PhoneNumberKit()
  var hashingManager = HashingManager()

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

  var currencyValidityValidator: CompositeValidator = {
    return CompositeValidator<String>(validators: [CurrencyStringValidator()])
  }()

  // MARK: - Outlets and Actions

  @IBOutlet var payTitleLabel: UILabel!
  @IBOutlet var closeButton: UIButton!

  @IBOutlet var primaryAmountTextField: LimitEditTextField!
  @IBOutlet var secondaryAmountLabel: UILabel!

  // Can display a formatted phone number or the Bitcoin address
  @IBOutlet var phoneNumberEntryView: PhoneNumberEntryView!
  @IBOutlet var bitcoinAddressButton: UIButton! {
    didSet {
      bitcoinAddressButton.isHidden = true
      bitcoinAddressButton.layer.cornerRadius = 4.0
      bitcoinAddressButton.layer.borderColor = Theme.Color.lightGrayOutline.color.cgColor
      bitcoinAddressButton.layer.borderWidth = 1.0
      bitcoinAddressButton.titleLabel?.font = Theme.Font.sendingAmountToAddress.font
      bitcoinAddressButton.setTitleColor(Theme.Color.grayText.color, for: .normal)
    }
  }

  @IBOutlet var recipientDisplayNameLabel: UILabel!
  @IBOutlet var recipientDisplayNumberLabel: UILabel!

  @IBOutlet var contactsButton: CompactActionButton!
  @IBOutlet var scanButton: CompactActionButton!
  @IBOutlet var pasteButton: CompactActionButton!
  @IBOutlet var sendButton: PrimaryActionButton!
  @IBOutlet var memoContainerView: SendPaymentMemoView!

  @IBAction func performClose() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  @IBAction func performPaste() {
    coordinationDelegate?.viewControllerDidSelectPaste(self)
    if let text = UIPasteboard.general.string {
      pasteRecipient(fromText: text)
    }
  }

  @IBAction func performContacts() {
    coordinationDelegate?.viewControllerDidPressContacts(self)
  }

  @IBAction func performScan() {
    let amount = viewModel.btcAmount ?? .zero
    coordinationDelegate?.viewControllerDidPressScan(self, btcAmount: amount, primaryCurrency: primaryCurrency)
  }

  @IBAction func performSend() {
    let amountString = sanitizedAmountString ?? ""

    do {
      try currencyValidityValidator.validate(value: amountString)
      try validateAmount(of: amountString)
      try validateAndSendPayment()
    } catch {
      showValidatorAlert(for: error, title: "Invalid Transaction")
    }
  }

  @IBAction func performStartPhoneEntry() {
    showPhoneEntryView(with: "")
    phoneNumberEntryView.textField?.becomeFirstResponder()
  }

  /// Each button should connect to this IBAction. This prevents automatically
  /// calling textFieldDidBeginEditing() if/when this view reappears.
  @IBAction func dismissKeyboard() {
    primaryAmountTextField.resignFirstResponder()
    phoneNumberEntryView.textField.resignFirstResponder()
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .sendPayment(.page)),
      (memoContainerView.memoLabel, .sendPayment(.memoLabel))
    ]
  }

  // MARK: - View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    registerForRateUpdates()
    updateRatesAndView()
    setupKeyboardDoneButton(for: [primaryAmountTextField, phoneNumberEntryView.textField], action: #selector(doneButtonWasPressed))
    setupListenerForTextViewChange()
    setupLabels()
    setupPhoneNumberEntryView(textFieldEnabled: true)
    formatPhoneNumberEntryView()
    memoContainerView.delegate = self
    let sharedMemoAllowed = coordinationDelegate?.viewControllerShouldInitiallyAllowMemoSharing(self) ?? true
    viewModel.sharedMemoAllowed = sharedMemoAllowed
    memoContainerView.configure(memo: nil, isShared: sharedMemoAllowed)
    coordinationDelegate?.sendPaymentViewControllerDidLoad(self)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    primaryAmountTextField.delegate = self
    updateViewWithModel()
  }

  @objc func primaryAmountTextFieldDidChange(_ textField: UITextField) {
    guard let amountString = sanitizedAmountString else { return }

    if amountString.isEmpty {
      secondaryAmountLabel.text = ""
    } else {
      let decimal = NSDecimalNumber(fromString: amountString) ?? .zero
      switch primaryCurrency {
      case .BTC:
        secondaryAmountLabel.text = createCurrencyConverter(for: decimal).amountStringWithSymbol(forCurrency: .USD) ?? CurrencyCode.USD.symbol
      case .USD:
        if let attributedText = createCurrencyConverter(for: decimal).attributedStringWithSymbol(forCurrency: .BTC) {
          secondaryAmountLabel.attributedText = attributedText
        } else {
          secondaryAmountLabel.text = createCurrencyConverter(for: decimal).amountStringWithSymbol(forCurrency: .BTC) ?? CurrencyCode.BTC.symbol
        }
      }
    }
  }

  @objc func doneButtonWasPressed() {
    dismissKeyboard()
  }

}

// MARK: - View Configuration

extension SendPaymentViewController {

  fileprivate func setupLabels() {
    recipientDisplayNameLabel.font = Theme.Font.sendingAmountTo.font
    recipientDisplayNumberLabel.font = Theme.Font.sendingAmountToPhoneNumber.font
    payTitleLabel.font = Theme.Font.onboardingSubtitle.font
    payTitleLabel.textColor = Theme.Color.darkBlueText.color
    secondaryAmountLabel.textColor = Theme.Color.grayText.color
    secondaryAmountLabel.font = Theme.Font.requestPaySecondaryCurrency.font
  }

  fileprivate func formatPhoneNumberEntryView() {
    guard let entryView = phoneNumberEntryView else { return }
    entryView.backgroundColor = UIColor.clear
    entryView.layer.borderColor = Theme.Color.lightGrayOutline.color.cgColor
    entryView.textField.delegate = self
    entryView.textField.backgroundColor = UIColor.clear
    entryView.textField.autocorrectionType = .no
    entryView.textField.font = Theme.Font.sendingAmountToAddress.font
    entryView.textField.textColor = Theme.Color.sendingToDarkGray.color
    entryView.textField.adjustsFontSizeToFitWidth = true
    entryView.textField.keyboardType = .numberPad
    entryView.textField.textAlignment = .center
    entryView.textField.isUserInteractionEnabled = true

    updateRecipientContainerContentType(forRecipient: viewModel.paymentRecipient)
  }

  fileprivate func setupListenerForTextViewChange() {
    primaryAmountTextField.addTarget(self, action: #selector(primaryAmountTextFieldDidChange), for: .editingChanged)
  }

  func updateViewWithModel() {
    loadAmounts()

    phoneNumberEntryView.textField.text = ""

    self.recipientDisplayNameLabel.text = viewModel.contact?.displayName
    self.recipientDisplayNumberLabel.text = viewModel.contact?.displayNumber

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
      recipientDisplayNumberLabel.text = viewModel.displayRecipientNumber()
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

  func pasteRecipient(fromText text: String) {
    do {
      let recipient = try viewModel.recipientParser.findSingleRecipient(inText: text, ofTypes: [.bitcoinURL, .phoneNumber])
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
          setBTCAmountAsPrimary(amount)
        }
      }
    }
  }

  func setBTCAmountAsPrimary(_ amount: NSDecimalNumber) {
    self.viewModel.btcAmount = amount
    self.viewModel.primaryCurrency = .BTC
  }

  private func fetchViewModelAndUpdate(forPaymentRequest url: URL) {
    self.alertManager?.showActivityHUD(withStatus: nil)
    self.coordinationDelegate?.resolveMerchantPaymentRequest(withURL: url) { result in
      let errorTitle = "Payment Request Error"
      switch result {
      case .success(let response):
        let parser = CKRecipientParser(kit: self.phoneNumberKit)
        guard let fetchedModel = SendPaymentViewModel(response: response, parser: parser),
          let fetchedAddress = fetchedModel.address,
          let fetchedAmount = fetchedModel.btcAmount else {
            self.showValidatorAlert(for: MerchantPaymentRequestError.missingOutput, title: errorTitle)
            return
        }

        self.viewModel = fetchedModel
        self.setPaymentRecipient(PaymentRecipient.btcAddress(fetchedAddress))
        self.setBTCAmountAsPrimary(fetchedAmount)

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
        self.showPhoneEntryView(with: contact)
      case .contact:
        self.hideRecipientInputViews()
      }
    }
  }

  private func showBitcoinAddressRecipient(with title: String) {
    self.bitcoinAddressButton.isHidden = false
    self.phoneNumberEntryView.isHidden = true
    self.bitcoinAddressButton.setTitle(title, for: .normal)
  }

  private func showPhoneEntryView(with title: String) {
    self.bitcoinAddressButton.isHidden = true
    self.phoneNumberEntryView.isHidden = false
    self.phoneNumberEntryView.textField.text = title
  }

  private func showPhoneEntryView(with contact: GenericContact) {
    self.bitcoinAddressButton.isHidden = true
    self.phoneNumberEntryView.isHidden = false

    let region = phoneNumberEntryView.selectedRegion ?? phoneNumberEntryView.defaultRegion
    let country = CKCountry(regionCode: region, kit: self.phoneNumberKit)
    let number = contact.globalPhoneNumber.nationalNumber

    self.phoneNumberEntryView.textField.update(withCountry: country, nationalNumber: number)
  }

  private func hideRecipientInputViews() {
    self.bitcoinAddressButton.isHidden = true
    self.phoneNumberEntryView.isHidden = true
  }

}

extension SendPaymentViewController: SelectedValidContactDelegate {
  func update(withSelectedContact contact: ContactType) {
    self.setPaymentRecipient(.contact(contact))
    self.updateViewWithModel()
  }

}

// MARK: - Amounts and Currencies

extension SendPaymentViewController {

  var primaryCurrency: CurrencyCode {
    return viewModel.primaryCurrency
  }

  func createCurrencyConverter(for decimal: NSDecimalNumber) -> CurrencyConverter {
    switch primaryCurrency {
    case .BTC:
      return CurrencyConverter(rates: rateManager.exchangeRates, fromAmount: decimal, fromCurrency: .BTC, toCurrency: .USD)
    default:
      return CurrencyConverter(rates: rateManager.exchangeRates, fromAmount: decimal, fromCurrency: .USD, toCurrency: .BTC)
    }
  }

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    if (primaryAmountTextField.text ?? "").isNotEmpty {
      let btcAmount = getBitcoinValueForPrimaryAmountText()
      viewModel.btcAmount = btcAmount
    }

    loadAmounts(forPrimary: false, forSecondary: true)
  }

  /// Removes the currency symbol and thousands separator from the primary text, based on Locale.current
  var sanitizedAmountString: String? {
    guard let toSanitize = primaryAmountTextField.text else { return nil }
    return toSanitize.removing(groupingSeparator: self.viewModel.groupingSeparator,
                               currencySymbol: primaryCurrency.symbol)
  }

  func getBitcoinValueForPrimaryAmountText() -> NSDecimalNumber {
    guard let amountString = sanitizedAmountString,
      let decimal = NSDecimalNumber(fromString: amountString) else { return .zero }
    return createCurrencyConverter(for: decimal).amount(forCurrency: .BTC) ?? 0.0
  }

  fileprivate func loadAmounts(forPrimary: Bool = true, forSecondary: Bool = true) {
    let labels = viewModel.amountLabels(withRates: rateManager.exchangeRates, withSymbols: true)

    if forPrimary {
      switch viewModel.primaryCurrency {
      case .USD:
        self.primaryAmountTextField.text = viewModel.primaryAmountInputText(withRates: rateManager.exchangeRates)
      case .BTC:
        if let primaryLabel = labels.primary {
          self.primaryAmountTextField.text = primaryLabel
        }
      }
    }

    if let secondaryLabel = labels.secondary, forSecondary {
      self.secondaryAmountLabel.attributedText = secondaryLabel
    }
  }

}

extension SendPaymentViewController: UITextFieldDelegate {

  func textFieldDidBeginEditing(_ textField: UITextField) {
    switch textField {
    case phoneNumberEntryView.textField:
      let defaultCountry = CKCountry(locale: .current, kit: self.phoneNumberKit)
      let phoneNumber = GlobalPhoneNumber(countryCode: defaultCountry.countryCode, nationalNumber: "")
      let contact = GenericContact(phoneNumber: phoneNumber, hash: "", formatted: "")
      let recipient = PaymentRecipient.phoneNumber(contact)
      setPaymentRecipient(recipient)
      updateViewWithModel()
    case primaryAmountTextField:
      guard let text = sanitizedAmountString,
        let number = NSDecimalNumber(fromString: text) else { return }
      if number == .zero {
        textField.text = primaryCurrency.symbol
      }
    default:
      break
    }
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    // Skip triggering changes/validation if textField is empty
    guard let text = textField.text, text.isNotEmpty else {
      return
    }

    switch textField {
    case phoneNumberEntryView.textField:
      let currentNumber = phoneNumberEntryView.textField.currentGlobalNumber()
      guard currentNumber.nationalNumber.isNotEmpty else { return } //don't attempt parsing if only dismissing keypad or changing country

      do {
        let recipient = try viewModel.recipientParser.findSingleRecipient(inText: text, ofTypes: [.phoneNumber])
        switch recipient {
        case .bitcoinURL: updateViewModel(withParsedRecipient: recipient)
        case .phoneNumber(let globalPhoneNumber):
          let salt = try hashingManager.salt()
          let hashedPhoneNumber = hashingManager.hash(phoneNumber: globalPhoneNumber, salt: salt)
          let formattedPhoneNumber = try CKPhoneNumberFormatter(kit: self.phoneNumberKit, format: .international)
            .string(from: globalPhoneNumber)
          let contact = GenericContact(phoneNumber: globalPhoneNumber, hash: hashedPhoneNumber, formatted: formattedPhoneNumber)
          let recipient = PaymentRecipient.phoneNumber(contact)
          setPaymentRecipient(recipient)
        }
      } catch {
        self.coordinationDelegate?.showAlertForInvalidContactOrPhoneNumber(contactName: nil, displayNumber: text)
      }

    case primaryAmountTextField:
      viewModel.btcAmount = getBitcoinValueForPrimaryAmountText()
      loadAmounts(forPrimary: false, forSecondary: true)
    default:
      break
    }
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if let pasteboardText = UIPasteboard.general.string, pasteboardText == string {
      pasteRecipient(fromText: pasteboardText)
    }

    switch textField {
    case primaryAmountTextField:
      guard let text = textField.text, let swiftRange = Range(range, in: text), isNotDeletingOrEditingCurrencySymbol(for: text, in: range) else {
        return false
      }

      let finalString = text.replacingCharacters(in: swiftRange, with: string)
      return primaryAmountTextFieldShouldChangeCharacters(inProposedString: finalString)

    case self.phoneNumberEntryView.textField:
      if string.isNotEmpty {
        phoneNumberEntryView.textField.selected(digit: string)
      } else {
        phoneNumberEntryView.textField.selectedBack()
      }
      return false  // manage this manually
    default:
      return true
    }
  }

  private func primaryAmountTextFieldShouldChangeCharacters(inProposedString finalString: String) -> Bool {
    let splitByDecimalArray = finalString.components(separatedBy: viewModel.decimalSeparator).dropFirst()

    if !splitByDecimalArray.isEmpty {
      guard splitByDecimalArray[1].count <= primaryCurrency.decimalPlaces else {
        return false
      }
    }

    guard finalString.count(of: viewModel.decimalSeparatorCharacter) <= 1 else {
      return false
    }

    let requiredSymbolString = primaryCurrency.symbol
    guard finalString.contains(requiredSymbolString) else {
      return false
    }

    let trimmedFinal = finalString.removing(groupingSeparator: self.viewModel.groupingSeparator, currencySymbol: requiredSymbolString)
    if trimmedFinal.isEmpty {
      return true // allow deletion of all digits by returning early
    }

    guard let newAmount = NSDecimalNumber(fromString: trimmedFinal) else { return false }

    guard newAmount.significantFractionalDecimalDigits <= primaryCurrency.decimalPlaces else {
      return false
    }

    let btcAmount = createCurrencyConverter(for: newAmount).amount(forCurrency: .BTC) ?? 0.0
    viewModel.btcAmount = btcAmount

    return true
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

  private func isNotDeletingOrEditingCurrencySymbol(for amount: String, in range: NSRange) -> Bool {
    return (amount != primaryCurrency.symbol || range.length == 0)
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

  func validateAmount(of trimmedAmountString: String) throws {
    let amountValidator = createCurrencyAmountValidator(ignoring: [.invitationMaximum])
    guard let decimal = NSDecimalNumber(fromString: trimmedAmountString), decimal.isNumber else {
      throw CurrencyAmountValidatorError.notANumber(trimmedAmountString)
    }

    let converter = createCurrencyConverter(for: decimal)
    try amountValidator.validate(value: converter)
  }

  private func validateInvitationMaximum(_ maximum: NSDecimalNumber) throws {
    guard let recipient = viewModel.paymentRecipient,
      case let .contact(contact) = recipient,
      contact.kind == .invite
      else { return }

    let validator = createCurrencyAmountValidator(ignoring: [.usableBalance, .transactionMinimum])
    let converter = createCurrencyConverter(for: maximum)
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

    coordinationDelegate?.viewControllerDidSendPayment(self,
                                                       btcAmount: getBitcoinValueForPrimaryAmountText(),
                                                       requiredFeeRate: self.viewModel.requiredFeeRate,
                                                       primaryCurrency: primaryCurrency,
                                                       address: address,
                                                       contact: nil,
                                                       rates: self.rateManager.exchangeRates,
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
    guard let amountString = sanitizedAmountString,
      let decimal = NSDecimalNumber(fromString: amountString)
      else { return }

    var newContact = contact
    newContact.kind = kind
    self.setPaymentRecipient(.contact(newContact))

    try validateInvitationMaximum(decimal)
    coordinationDelegate?.viewControllerDidBeginAddressNegotiation(self,
                                                                   btcAmount: getBitcoinValueForPrimaryAmountText(),
                                                                   primaryCurrency: primaryCurrency,
                                                                   contact: newContact,
                                                                   memo: self.viewModel.memo,
                                                                   rates: self.rateManager.exchangeRates,
                                                                   memoIsShared: self.viewModel.sharedMemoDesired,
                                                                   sharedPayload: sharedPayload)
  }

  private func handleContactValidationError(_ error: Error) {
    self.showValidatorAlert(for: error, title: "")
  }

  private func validateRegisteredContact(_ contact: ContactType, sharedPayload: SharedPayloadDTO) {
    coordinationDelegate?.viewController(self, checkingCachedAddressesFor: contact.phoneNumberHash, completion: { [weak self] result in
      guard let strongSelf = self else { return }

      switch result {
      case .success(let addressResponses):

        if let addressResponse = addressResponses.first(where: { $0.phoneNumberHash == contact.phoneNumberHash }) {
          var updatedPayload = sharedPayload
          updatedPayload.updatePubKeyState(with: addressResponse)
          strongSelf.coordinationDelegate?.viewControllerDidSendPayment(strongSelf,
                                                                        btcAmount: strongSelf.getBitcoinValueForPrimaryAmountText(),
                                                                        requiredFeeRate: strongSelf.viewModel.requiredFeeRate,
                                                                        primaryCurrency: strongSelf.primaryCurrency,
                                                                        address: addressResponse.address,
                                                                        contact: contact,
                                                                        rates: strongSelf.rateManager.exchangeRates,
                                                                        sharedPayload: updatedPayload)
        } else {
          // The contact has not backed up their words so our fetch didn't return an address, degrade to address negotiation
          do {
            try strongSelf.validateAmountAndBeginAddressNegotiation(for: contact, kind: .registeredUser, sharedPayload: sharedPayload)
          } catch {
            strongSelf.handleContactValidationError(error)
          }
        }

      case .failure(let error):
        strongSelf.handleContactValidationError(error)
      }
    })
  }

  private func validateGenericContact(_ contact: ContactType, sharedPayload: SharedPayloadDTO) {
    // Sending payment to generic contact (manually entered phone number) will first check if they have addresses on server
    coordinationDelegate?.viewControllerDidRequestVerificationCheck(self) { [weak self] in
      guard let localSelf = self,
        let delegate = localSelf.coordinationDelegate
        else { return }

      delegate.viewController(localSelf, checkingCachedAddressesFor: contact.phoneNumberHash, completion: { [weak self] result in
        self?.handleGenericContactAddressCheckCompletion(forContact: contact, sharedPayload: sharedPayload, result: result)
      })
    }
  }

  private func handleGenericContactAddressCheckCompletion(forContact contact: ContactType,
                                                          sharedPayload: SharedPayloadDTO,
                                                          result: Result<[WalletAddressesQueryResponse], UserProviderError>) {
    let btcValue = getBitcoinValueForPrimaryAmountText()
    var newContact = contact

    switch result {
    case .success(let addressResponses):
      if let addressResponse = addressResponses.first(where: { $0.phoneNumberHash == contact.phoneNumberHash }) {
        var updatedPayload = sharedPayload
        updatedPayload.updatePubKeyState(with: addressResponse)

        newContact.kind = .registeredUser
        self.coordinationDelegate?.viewControllerDidSendPayment(self,
                                                                btcAmount: btcValue,
                                                                requiredFeeRate: self.viewModel.requiredFeeRate,
                                                                primaryCurrency: self.primaryCurrency,
                                                                address: addressResponse.address,
                                                                contact: contact,
                                                                rates: self.rateManager.exchangeRates,
                                                                sharedPayload: updatedPayload)
      } else {
        do {
          try validateAmountAndBeginAddressNegotiation(for: newContact, kind: .invite, sharedPayload: sharedPayload)
        } catch {
          self.handleContactValidationError(error)
        }
      }
    case .failure(let error):
      self.handleContactValidationError(error)
    }
  }

}
