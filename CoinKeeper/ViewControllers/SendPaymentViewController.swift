//
//  SendPaymentViewController.swift
//  DropBit
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
import SVProgressHUD

typealias SendPaymentViewControllerCoordinator = SendPaymentViewControllerDelegate &
  CurrencyValueDataSourceType & BalanceDataSource & PaymentRequestResolver & URLOpener &
  ViewControllerDismissable & AnalyticsManagerAccessType & MemoEntryDelegate

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

  private var currentTypeDisplay: WalletTransactionType?

  var editAmountViewModel: CurrencySwappableEditAmountViewModel {
    return viewModel
  }

  /// The presenter of SendPaymentViewController can set this property to provide a recipient.
  /// It will be parsed and used to update the viewModel and view when ready.
  var recipientDescriptionToLoad: String?

  var countryCodeSearchView: CountryCodeSearchView?
  let countryCodeDataSource = CountryCodePickerDataSource()

  private(set) weak var delegate: SendPaymentViewControllerCoordinator!

  var currencyValueManager: CurrencyValueDataSourceType? {
    return delegate
  }

  var balanceDataSource: BalanceDataSource? {
    return delegate
  }

  // MARK: - Outlets and Actions

  @IBOutlet var closeButton: UIButton!

  @IBOutlet var editAmountView: CurrencySwappableEditAmountView!
  @IBOutlet var phoneNumberEntryView: PhoneNumberEntryView!
  @IBOutlet var walletToggleView: WalletToggleView!

  @IBOutlet var addressScanButtonContainerView: UIView!
  @IBOutlet var destinationButton: UIButton!
  @IBOutlet var scanButton: PrimaryActionButton!

  @IBOutlet var recipientDisplayNameLabel: UILabel!
  @IBOutlet var recipientDisplayNumberLabel: UILabel!

  @IBOutlet var contactsButton: CompactActionButton!
  @IBOutlet var twitterButton: CompactActionButton!
  @IBOutlet var pasteButton: CompactActionButton!

  @IBOutlet var nextButton: PrimaryActionButton!
  @IBOutlet var memoContainerView: SendPaymentMemoView!
  @IBOutlet var sendMaxButton: LightBorderedButton!

  @IBAction func performClose() {
    delegate.sendPaymentViewControllerWillDismiss(self)
  }

  @IBAction func performPaste() {
    delegate.viewControllerDidSelectPaste(self)
    if let text = UIPasteboard.general.string {
      applyRecipient(inText: text)
    }
  }

  @IBAction func performContacts() {
    delegate.viewControllerDidPressContacts(self)
  }

  @IBAction func performTwitter() {
    delegate.viewControllerDidPressTwitter(self)
  }

  @IBAction func performScan() {
    let converter = viewModel.currencyConverter
    delegate.viewControllerDidPressScan(self,
                                        btcAmount: converter.btcAmount,
                                        primaryCurrency: primaryCurrency)
  }

  @IBAction func performNext() {
    configureFinalMemoShareStatus()

    do {
      try validateAndSendPayment()
    } catch {
      showValidatorAlert(for: error, title: "Invalid Transaction")
    }
  }

  @IBAction func performSendMax() {
    let tempAddress = ""
    self.delegate.latestFees()
      .compactMap { self.delegate.usableFeeRate(from: $0) }
      .then { feeRate -> Promise<CNBTransactionData> in
        guard let delegate = self.delegate else { fatalError("delegate is required") }
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
        self.delegate.viewControllerDidRequestAlert(self, viewModel: alertViewModel)
    }
  }

  @IBAction func performStartPhoneEntry() {
    showPhoneEntryView(with: "")
    phoneNumberEntryView.textField?.becomeFirstResponder()
    editAmountView.isUserInteractionEnabled = true
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

  static func newInstance(
    delegate: SendPaymentViewControllerCoordinator,
    viewModel: SendPaymentViewModel,
    alertManager: AlertManagerType? = nil) -> SendPaymentViewController {
    let vc = SendPaymentViewController.makeFromStoryboard()
    vc.delegate = delegate
    vc.viewModel = viewModel
    vc.viewModel.delegate = vc
    vc.alertManager = alertManager
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
    editAmountView.delegate = self
    refreshBothAmounts()
    let sharedMemoAllowed = delegate.viewControllerShouldInitiallyAllowMemoSharing(self)
    viewModel.sharedMemoAllowed = sharedMemoAllowed
    memoContainerView.configure(memo: nil, isShared: sharedMemoAllowed)
    delegate.sendPaymentViewControllerDidLoad(self)
    walletToggleView.delegate = self
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

  override func unlock() {
    walletToggleView.isHidden = false
  }

  override func lock() {
    walletToggleView.isHidden = true
  }

  override func makeUnavailable() {
    lock()
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
    guard currentTypeDisplay != viewModel.walletTransactionType else { return }
    currentTypeDisplay = viewModel.walletTransactionType

    switch viewModel.walletTransactionType {
    case .lightning:
      scanButton.style = .lightning(rounded: true)
      contactsButton.style = .lightning(rounded: true)
      twitterButton.style = .lightning(rounded: true)
      pasteButton.style = .lightning(rounded: true)
      nextButton.style = .lightning(rounded: true)
      walletToggleView.selectLightningButton()
    case .onChain:
      scanButton.style = .bitcoin(rounded: true)
      contactsButton.style = .bitcoin(rounded: true)
      twitterButton.style = .bitcoin(rounded: true)
      pasteButton.style = .bitcoin(rounded: true)
      nextButton.style = .bitcoin(rounded: true)
      walletToggleView.selectBitcoinButton()
    }

    moveCursorToCorrectLocationIfNecessary()
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
    scanButton.applyCornerRadius(4, toCorners: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner])
    addressScanButtonContainerView.applyCornerRadius(4)
    addressScanButtonContainerView.layer.borderColor = UIColor.mediumGrayBorder.cgColor
    addressScanButtonContainerView.layer.borderWidth = 1.0

    destinationButton.titleLabel?.font = .medium(14)
    destinationButton.setTitleColor(.darkGrayText, for: .normal)
    destinationButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
  }

  fileprivate func configureFinalMemoShareStatus() {
    if viewModel.memo?.asNilIfEmpty() == nil {
      viewModel.sharedMemoDesired = false
      updateMemoContainer()
    }
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

  func resetViewModelWithUI() {
    let sharedMemoAllowed = delegate.viewControllerShouldInitiallyAllowMemoSharing(self)
    viewModel.sharedMemoAllowed = sharedMemoAllowed

    setupStyle()
    updateViewWithModel()
  }

  func updateViewWithModel() {
    if viewModel.btcAmount != .zero || viewModel.walletTransactionType == .lightning {
      sendMaxButton.isHidden = true
    } else {
      sendMaxButton.isHidden = false
    }

    let allowEditingAmount = !viewModel.hasInvoiceWithAmount
    editAmountView.enableEditing(allowEditingAmount)

    phoneNumberEntryView.textField.text = ""
    self.updateRecipientContainerContentType(forRecipient: viewModel.paymentRecipient)

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

    refreshBothAmounts()
    updateMemoContainer()
    setupStyle()
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
      let recipient = try viewModel.recipientParser.findSingleRecipient(inText: text, ofTypes: viewModel.validParsingRecipientTypes)
      editAmountView.primaryAmountTextField.resignFirstResponder()
      updateViewModel(withParsedRecipient: recipient)
    } catch {
      self.viewModel.paymentRecipient = nil
      delegate.viewControllerDidAttemptInvalidDestination(self, error: error)
    }

    updateViewWithModel()
    phoneNumberEntryView.resignFirstResponder()
  }

  func updateViewModel(withParsedRecipient parsedRecipient: CKParsedRecipient) {
    switch parsedRecipient {
    case .lightningURL(let url):
      handleLightningInvoicePaste(lightningUrl: url)
    case .phoneNumber:
      self.viewModel.paymentRecipient = PaymentRecipient(parsedRecipient: parsedRecipient)
    case .bitcoinURL(let bitcoinURL):
      viewModel.walletTransactionType = .onChain
      if let paymentRequest = bitcoinURL.components.paymentRequest {
        self.fetchViewModelAndUpdate(forPaymentRequest: paymentRequest)
      } else {
        self.viewModel.paymentRecipient = PaymentRecipient(parsedRecipient: parsedRecipient)
        if let amount = bitcoinURL.components.amount {
          self.viewModel.setBTCAmountAsPrimary(amount)
        }
      }
    }

    resetViewModelWithUI()
  }

  private func handleLightningInvoicePaste(lightningUrl: LightningURL) {
    self.alertManager?.showActivityHUD(withStatus: nil)
    delegate.viewControllerDidReceiveLightningURLToDecode(lightningUrl)
      .get { decodedInvoice in
        self.delegate.viewControllerShouldTrackEvent(event: .externalLightningInvoiceInput)
        self.alertManager?.hideActivityHUD(withDelay: nil, completion: {
          let viewModel = SendPaymentViewModel(encodedInvoice: lightningUrl.invoice,
                                               decodedInvoice: decodedInvoice,
                                               exchangeRates: self.viewModel.exchangeRates,
                                               currencyPair: self.viewModel.currencyPair,
                                               delegate: self)
          self.applyFetchedBitcoinModelAndUpdateView(fetchedModel: viewModel)

        })
      }.catch { error in
        self.handleError(error: error)
    }
  }

  private func handleError(error: Error) {
    self.alertManager?.hideActivityHUD(withDelay: nil) {
      let viewModel = AlertControllerViewModel(title: "", description: error.localizedDescription)
      self.delegate.viewControllerDidRequestAlert(self, viewModel: viewModel)
    }
  }

  private func fetchViewModelAndUpdate(forPaymentRequest url: URL) {
    self.alertManager?.showActivityHUD(withStatus: nil)
    self.delegate.resolveMerchantPaymentRequest(withURL: url) { result in
      let errorTitle = "Payment Request Error"
      switch result {
      case .success(let response):
        let maybeFetchedModel = SendPaymentViewModel(response: response,
                                                     walletTransactionType: self.viewModel.walletTransactionType,
                                                     exchangeRates: self.viewModel.exchangeRates,
                                                     fiatCurrency: self.viewModel.fiatCurrency)
        guard let fetchedModel = maybeFetchedModel, fetchedModel.address != nil else {
            self.showValidatorAlert(for: MerchantPaymentRequestError.missingOutput, title: errorTitle)
            return
        }

        self.applyFetchedBitcoinModelAndUpdateView(fetchedModel: fetchedModel)

      case .failure(let error):
        self.handleError(error: error)
      }
    }
  }

  func applyFetchedBitcoinModelAndUpdateView(fetchedModel: SendPaymentViewModel) {
    self.viewModel = fetchedModel
    self.setupCurrencySwappableEditAmountView()
    self.viewModel.setBTCAmountAsPrimary(fetchedModel.btcAmount)
    self.alertManager?.hideActivityHUD(withDelay: nil) {
      self.updateViewWithModel()
    }
  }

  func updateRecipientContainerContentType(forRecipient paymentRecipient: PaymentRecipient?) {
    DispatchQueue.main.async {
      guard let recipient = paymentRecipient else {
        let isLightning = self.viewModel.walletTransactionType == .lightning
        let paymentTargetDesc = isLightning ? "Invoice" : "BTC Address"
        self.showPaymentTargetRecipient(with: "To: \(paymentTargetDesc) or phone number")
        return
      }
      switch recipient {
      case .paymentTarget(let paymentTarget):
        self.showPaymentTargetRecipient(with: paymentTarget)
      case .phoneNumber(let contact):
        self.delegate.viewController(self, checkForContactFromGenericContact: contact) { possibleValidatedContact in
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
        self.delegate.viewController(self, checkForVerifiedTwitterContact: twitterContact)
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

  private func showPaymentTargetRecipient(with title: String) {
    self.addressScanButtonContainerView.isHidden = false
    self.phoneNumberEntryView.isHidden = true
    self.destinationButton.setTitle(title, for: .normal)
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
    self.viewModel.paymentRecipient = .contact(contact)
    updateViewWithModel()
  }

  func update(withSelectedTwitterUser twitterUser: TwitterUser) {
    var contact = TwitterContact(twitterUser: twitterUser)
    updateViewWithModel()

    let addressType = self.viewModel.walletTransactionType.addressType
    delegate.viewControllerDidRequestRegisteredAddress(self, ofType: addressType, forIdentity: twitterUser.idStr)
      .done { (responses: [WalletAddressesQueryResponse]) in
        contact.kind = (responses.isEmpty) ? .invite : .registeredUser
        self.viewModel.paymentRecipient = .twitterContact(contact)
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
    self.viewModel.paymentRecipient = recipient
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
      case .bitcoinURL, .lightningURL: updateViewModel(withParsedRecipient: recipient)
      case .phoneNumber(let globalPhoneNumber):
        let formattedPhoneNumber = try CKPhoneNumberFormatter(format: .international)
          .string(from: globalPhoneNumber)
        let contact = GenericContact(phoneNumber: globalPhoneNumber, formatted: formattedPhoneNumber)
        let recipient = PaymentRecipient.phoneNumber(contact)
        self.viewModel.paymentRecipient = recipient
      }
    } catch {
      self.delegate.showAlertForInvalidContactOrPhoneNumber(contactName: nil, displayNumber: text)
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
    delegate.showAlertForInvalidContactOrPhoneNumber(contactName: nil, displayNumber: phoneNumber.asE164())
  }
}

extension SendPaymentViewController: SendPaymentMemoViewDelegate {

  func didTapMemoButton() {
    delegate.viewControllerDidSelectMemoButton(self, memo: viewModel.memo) { [weak self] memo in
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
    delegate.openURL(url, completionHandler: nil)
  }

}

// MARK: Validation

extension SendPaymentViewController {

  func validateAmount() throws {
    let ignoredOptions = viewModel.standardIgnoredOptions
    let amountValidator = createCurrencyAmountValidator(ignoring: ignoredOptions, balanceToCheck: viewModel.walletTransactionType)
    try amountValidator.validate(value: viewModel.currencyConverter)
  }

  private func validateInvitationMaximum(against btcAmount: NSDecimalNumber) throws {
    guard let recipient = viewModel.paymentRecipient,
      case let .contact(contact) = recipient,
      contact.kind != .registeredUser
      else { return }

    let ignoredOptions = viewModel.invitationMaximumIgnoredOptions
    let validator = createCurrencyAmountValidator(ignoring: ignoredOptions, balanceToCheck: viewModel.walletTransactionType)
    let validationConverter = CurrencyConverter(btcFromAmount: btcAmount, converter: viewModel.currencyConverter)
    try validator.validate(value: validationConverter)
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
    case .paymentTarget(let paymentTarget):
      try validatePayment(toTarget: paymentTarget, matches: viewModel.validPaymentRecipientType)
    case .twitterContact(let contact):
      try validatePayment(toContact: contact)
    }
  }

  private func sharedAmountInfo() -> SharedPayloadAmountInfo {
    return SharedPayloadAmountInfo(fiatCurrency: .USD, fiatAmount: 1)
  }

  private func validatePayment(toTarget paymentTarget: String, matches type: CKRecipientType) throws {
    let recipient = try viewModel.recipientParser.findSingleRecipient(inText: paymentTarget, ofTypes: [type])
    let ignoredValidation: CurrencyAmountValidationOptions = type != .phoneNumber ? viewModel.standardIgnoredOptions : []

    // This is still required here to pass along the local memo
    let sharedPayloadDTO = SharedPayloadDTO(addressPubKeyState: .none,
                                            walletTxType: viewModel.walletTransactionType,
                                            sharingDesired: viewModel.sharedMemoDesired,
                                            memo: viewModel.memo,
                                            amountInfo: sharedAmountInfo())

    try CurrencyAmountValidator(balancesNetPending: delegate.balancesNetPending(),
                                                    balanceToCheck: viewModel.walletTransactionType,
                                                    ignoring: ignoredValidation).validate(value:
                                                      viewModel.currencyConverter)

    switch recipient {
    case .bitcoinURL(let url):
      guard let address = url.components.address else {
        throw BitcoinAddressValidatorError.isInvalidBitcoinAddress
      }
      sendTransactionForConfirmation(with: viewModel.sendMaxTransactionData,
                                     paymentTarget: address,
                                     contact: nil,
                                     sharedPayload: sharedPayloadDTO)
    case .lightningURL(let url):
      try LightningInvoiceValidator().validate(value: url.invoice)
      sendTransactionForConfirmation(with: viewModel.sendMaxTransactionData,
                                     paymentTarget: url.invoice,
                                     contact: nil,
                                     sharedPayload: sharedPayloadDTO)
    default:
      break
    }
  }

  /// This evaluates the contact, some of it asynchronously, before sending
  private func validatePayment(toContact contact: ContactType) throws {
    let sharedPayload = SharedPayloadDTO(addressPubKeyState: .invite,
                                         walletTxType: self.viewModel.walletTransactionType,
                                         sharingDesired: self.viewModel.sharedMemoDesired,
                                         memo: self.viewModel.memo,
                                         amountInfo: sharedAmountInfo())
    switch contact.kind {
    case .invite:
      try validateAmountAndBeginAddressNegotiation(for: contact, kind: .invite, sharedPayload: sharedPayload)
    case .registeredUser:
      try validateRegisteredContact(contact, sharedPayload: sharedPayload)
    case .generic:
      validateGenericContact(contact, sharedPayload: sharedPayload)
    }
  }

  private func validateAmountAndBeginAddressNegotiation(for contact: ContactType,
                                                        kind: ContactKind,
                                                        sharedPayload: SharedPayloadDTO) throws {
    let btcAmount = viewModel.btcAmount

    var newContact = contact
    newContact.kind = kind
    switch contact.asDropBitReceiver {
    case .phone(let contact): self.viewModel.paymentRecipient = .contact(contact)
    case .twitter(let contact): self.viewModel.paymentRecipient = .twitterContact(contact)
    }

    try validateInvitationMaximum(against: btcAmount)
    try CurrencyAmountValidator(balancesNetPending: delegate.balancesNetPending(),
                                balanceToCheck: viewModel.walletTransactionType).validate(value:
                                  viewModel.currencyConverter)
    let inputs = SendingDelegateInputs(sendPaymentVM: self.viewModel, contact: newContact, payloadDTO: sharedPayload)

    delegate.viewControllerDidBeginAddressNegotiation(self,
                                                      btcAmount: btcAmount,
                                                      inputs: inputs)
  }

  private func handleContactValidationError(_ error: Error) {
    self.showValidatorAlert(for: error, title: "")
  }

  private func validateRegisteredContact(_ contact: ContactType, sharedPayload: SharedPayloadDTO) throws {
    try validateAmount()
    let addressType = self.viewModel.walletTransactionType.addressType
    delegate.viewControllerDidRequestRegisteredAddress(self, ofType: addressType, forIdentity: contact.identityHash)
      .done { (responses: [WalletAddressesQueryResponse]) in
        if responses.isEmpty && addressType == .lightning {
          do {
            try self.validateAmountAndBeginAddressNegotiation(for: contact, kind: .invite, sharedPayload: sharedPayload)
          } catch {
            self.handleContactValidationError(error)
          }
        } else if let addressResponse = responses.first(where: { $0.identityHash == contact.identityHash }) {
          var updatedPayload = sharedPayload
          updatedPayload.updatePubKeyState(with: addressResponse)
          self.sendTransactionForConfirmation(with: self.viewModel.sendMaxTransactionData,
                                              paymentTarget: addressResponse.address,
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
    let addressType = self.viewModel.walletTransactionType.addressType

    // Sending payment to generic contact (manually entered phone number) will first check if they have addresses on server
    delegate.viewControllerDidRequestVerificationCheck(self) { [weak self] in
      guard let localSelf = self, let delegate = localSelf.delegate else { return }

      delegate.viewControllerDidRequestRegisteredAddress(localSelf, ofType: addressType, forIdentity: contact.identityHash)
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

    let addressType = sharedPayload.walletTxType.addressType
    if responses.isEmpty && addressType == .lightning {
      do {
        try self.validateAmountAndBeginAddressNegotiation(for: contact, kind: .invite, sharedPayload: sharedPayload)
      } catch {
        self.handleContactValidationError(error)
      }
    } else if let addressResponse = responses.first(where: { $0.identityHash == contact.identityHash }) {
      var updatedPayload = sharedPayload
      updatedPayload.updatePubKeyState(with: addressResponse)

      newContact.kind = .registeredUser
      sendTransactionForConfirmation(with: viewModel.sendMaxTransactionData,
                                     paymentTarget: addressResponse.address,
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
                                              paymentTarget: String,
                                              contact: ContactType?,
                                              sharedPayload: SharedPayloadDTO) {
    let inputs = SendingDelegateInputs(sendPaymentVM: self.viewModel,
                                       contact: contact,
                                       payloadDTO: sharedPayload)

    if let data = viewModel.sendMaxTransactionData {
      delegate.viewController(self, sendingMax: data, to: paymentTarget, inputs: inputs)
    } else {
      self.delegate.viewControllerDidSendPayment(self,
                                                 btcAmount: viewModel.btcAmount,
                                                 requiredFeeRate: viewModel.requiredFeeRate,
                                                 paymentTarget: paymentTarget,
                                                 inputs: inputs)
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
    guard viewModel.walletTransactionType != .onChain else { return }
    viewModel.walletTransactionType = .onChain
    refreshAfterToggle()
  }

  func lightningWalletButtonWasTouched() {
    guard viewModel.walletTransactionType != .lightning else { return }
    viewModel.walletTransactionType = .lightning
    refreshAfterToggle()
  }

  private func refreshAfterToggle() {
    if let recipient = viewModel.paymentRecipient, case .paymentTarget = recipient {
      viewModel.paymentRecipient = nil //bitcoin addresses aren't valid for lightning and vice versa
    }
    resetViewModelWithUI()
    moveCursorToCorrectLocationIfNecessary()
  }

}
