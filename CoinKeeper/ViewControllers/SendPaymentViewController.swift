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
  ExchangeRateUpdateable,
  PaymentAmountValidatable,
  PhoneNumberEntryViewDisplayable,
ValidatorAlertDisplayable {

  var viewModel: SendPaymentViewModelType = SendPaymentViewModel(btcAmount: 0, primaryCurrency: .USD)
  var alertManager: AlertManagerType?
  let rateManager = ExchangeRateManager()
  let phoneNumberKit = PhoneNumberKit()
  var hashingManager = HashingManager()

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

  var currencyValidityValidator: CompositeValidator = {
    return CompositeValidator<String>(validators: [CurrencyStringValidator()])
  }()

  // MARK: - Outlets and Actions

  @IBOutlet var payTitleLabel: UILabel!
  @IBOutlet var closeButton: UIButton!

  @IBOutlet var primaryAmountTextField: LimitEditTextField!
  @IBOutlet var secondaryAmountLabel: UILabel!

  @IBOutlet var phoneNumberEntryView: PhoneNumberEntryView!

  @IBOutlet var addressScanButtonContainerView: UIView!
  @IBOutlet var bitcoinAddressButton: UIButton!
  @IBOutlet var scanButton: UIButton!

  @IBOutlet var recipientDisplayNameLabel: UILabel!
  @IBOutlet var recipientDisplayNumberLabel: UILabel!

  @IBOutlet var contactsButton: CompactActionButton!
  @IBOutlet var twitterButton: CompactActionButton!
  @IBOutlet var pasteButton: CompactActionButton!

  @IBOutlet var sendButton: PrimaryActionButton!
  @IBOutlet var memoContainerView: SendPaymentMemoView!
  @IBOutlet var sendMaxButton: LightBorderedButton!
  @IBOutlet var toggleCurrencyButton: UIButton!

  @IBAction func performClose() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
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

  @IBAction func performSendMax() {
    let tempAddress = ""
    self.coordinationDelegate?.latestFees()
      .compactMap { $0[.good] }
      .then { feeRate -> Promise<CNBTransactionData> in
        guard let delegate = self.coordinationDelegate else { fatalError("coordinationDelegate is required") }
        return delegate.viewController(self, sendMaxFundsTo: tempAddress, feeRate: feeRate)
      }
      .done {txData in
        self.viewModel.sendMax(with: txData)
        self.loadAmounts()
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

  @IBAction func performCurrencyToggle() {
    viewModel.togglePrimaryCurrency()
    updateViewWithModel()
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

    setupMenuController()
    registerForRateUpdates()
    updateRatesAndView()
    setupKeyboardDoneButton(for: [primaryAmountTextField, phoneNumberEntryView.textField], action: #selector(doneButtonWasPressed))
    setupListenerForTextViewChange()
    setupLabels()
    setupButtons()
    formatAddressScanView()
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

    if let recipientDescription = self.recipientDescriptionToLoad {
      self.applyRecipient(inText: recipientDescription)
      self.recipientDescriptionToLoad = nil
    } else {
      updateViewWithModel()
    }
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

  fileprivate func setupButtons() {
    let textColor = Theme.Color.whiteText.color
    let font = Theme.Font.compactButtonTitle.font
    let contactsTitle = NSAttributedString(imageName: "contactsIcon",
                                           imageSize: CGSize(width: 9, height: 14),
                                           title: "CONTACTS",
                                           textColor: textColor,
                                           font: font)
    contactsButton.setAttributedTitle(contactsTitle, for: .normal)

    let twitterTitle = NSAttributedString(imageName: "twitterBird",
                                          imageSize: CGSize(width: 20, height: 16),
                                          title: "TWITTER",
                                          textColor: textColor,
                                          font: font)
    twitterButton.setAttributedTitle(twitterTitle, for: .normal)

    let pasteTitle = NSAttributedString(imageName: "pasteIcon",
                                        imageSize: CGSize(width: 16, height: 14),
                                        title: "PASTE",
                                        textColor: textColor,
                                        font: font)
    pasteButton.setAttributedTitle(pasteTitle, for: .normal)
  }

  fileprivate func formatAddressScanView() {
    addressScanButtonContainerView.applyCornerRadius(4)
    addressScanButtonContainerView.layer.borderColor = Theme.Color.lightGrayOutline.color.cgColor
    addressScanButtonContainerView.layer.borderWidth = 1.0

    bitcoinAddressButton.titleLabel?.font = Theme.Font.sendingAmountToAddress.font
    bitcoinAddressButton.setTitleColor(Theme.Color.grayText.color, for: .normal)

    scanButton.backgroundColor = Theme.Color.backgroundDarkGray.color
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

  fileprivate func setupMenuController() {
    let controller = UIMenuController.shared
    let pasteItem = UIMenuItem(title: "Paste", action: #selector(performPaste))
    controller.menuItems = [pasteItem]
    controller.update()
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

    if viewModel.btcAmount != .zero {
      sendMaxButton.isHidden = true
    }
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
        guard let fetchedModel = SendPaymentViewModel(response: response),
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
        if let validatedContact = self.coordinationDelegate?.viewController(self, checkForContactFromGenericContact: contact) {
          self.viewModel.paymentRecipient = PaymentRecipient.contact(validatedContact)
          self.updateViewWithModel()
          self.hideRecipientInputViews()
        } else {
          self.showPhoneEntryView(with: contact)
        }
      case .contact:
        self.hideRecipientInputViews()
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
    let country = CKCountry(regionCode: region, kit: self.phoneNumberKit)
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
      sendMaxButton.isHidden = true
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
          let hashedPhoneNumber = hashingManager.hash(phoneNumber: globalPhoneNumber, salt: salt, parsedNumber: nil, kit: self.phoneNumberKit)
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
      sendMaxButton.isHidden = viewModel.btcAmount != .zero
      primaryAmountTextField.text = viewModel.primaryAmountInputText(withRates: self.rateManager.exchangeRates)
      loadAmounts(forPrimary: false, forSecondary: true)
    default:
      break
    }
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if let pasteboardText = UIPasteboard.general.string, pasteboardText == string {
      applyRecipient(inText: pasteboardText)
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
    let ignoredOptions = viewModel.standardIgnoredOptions
    let amountValidator = createCurrencyAmountValidator(ignoring: ignoredOptions)
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

    let ignoredOptions = viewModel.invitationMaximumIgnoredOptions
    let validator = createCurrencyAmountValidator(ignoring: ignoredOptions)
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

        if let addressResponse = addressResponses.first(where: { $0.identityHash == contact.phoneNumberHash }) {
          var updatedPayload = sharedPayload
          updatedPayload.updatePubKeyState(with: addressResponse)
          strongSelf.sendTransactionForConfirmation(with: strongSelf.viewModel.sendMaxTransactionData,
                                                    address: addressResponse.address,
                                                    contact: contact,
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
    var newContact = contact

    switch result {
    case .success(let addressResponses):
      if let addressResponse = addressResponses.first(where: { $0.identityHash == contact.phoneNumberHash }) {
        var updatedPayload = sharedPayload
        updatedPayload.updatePubKeyState(with: addressResponse)

        newContact.kind = .registeredUser
        sendTransactionForConfirmation(with: viewModel.sendMaxTransactionData,
                                       address: addressResponse.address,
                                       contact: contact,
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

  private func sendTransactionForConfirmation(with data: CNBTransactionData?,
                                              address: String,
                                              contact: ContactType?,
                                              sharedPayload: SharedPayloadDTO) {
    let rates = rateManager.exchangeRates
    if let data = viewModel.sendMaxTransactionData {
      coordinationDelegate?.viewController(self,
                                           sendingMax: data,
                                           address: address,
                                           contact: contact,
                                           rates: rates,
                                           sharedPayload: sharedPayload)
    } else {
      self.coordinationDelegate?.viewControllerDidSendPayment(self,
                                                              btcAmount: getBitcoinValueForPrimaryAmountText(),
                                                              requiredFeeRate: viewModel.requiredFeeRate,
                                                              primaryCurrency: primaryCurrency,
                                                              address: address,
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
