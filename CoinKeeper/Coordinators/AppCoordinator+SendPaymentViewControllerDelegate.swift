//
//  AppCoordinator+SendPaymentViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import Contacts
import enum Result.Result
import PromiseKit
import CNBitcoinKit
import Permission

extension AppCoordinator: SendPaymentViewControllerDelegate {

  func viewControllerDidRequestAlert(_ viewController: UIViewController, viewModel: AlertControllerViewModel) {
    let alert: AlertControllerType
    if viewModel.actions.isEmpty {
      alert = alertManager.defaultAlert(withTitle: viewModel.title, description: viewModel.description)
    } else {
      alert = alertManager.alert(from: viewModel)
    }

    navigationController.topViewController()?.show(alert, sender: nil)
  }

  func sendPaymentViewControllerDidLoad(_ viewController: UIViewController) {
    analyticsManager.track(event: .payScreenLoaded, with: nil)
  }

  func viewControllerDidSelectPaste(_ viewController: UIViewController) {
    analyticsManager.track(event: .pasteButtonPressed, with: nil)
  }

  func viewControllerDidPressTwitter(_ viewController: UIViewController & SelectedValidContactDelegate) {
    analyticsManager.track(event: .twitterButtonPressed, with: nil)
    let context = persistenceManager.mainQueueContext()
    guard persistenceManager.brokers.user.userIsVerified(using: .twitter, in: context) else {
      showModalForTwitterVerification(with: viewController)
      return
    }

    self.presentContacts(mode: .twitter, selectionDelegate: viewController)
  }

  func viewControllerDidBeginAddressNegotiation(_ viewController: UIViewController,
                                                btcAmount: NSDecimalNumber,
                                                primaryCurrency: CurrencyCode,
                                                contact: ContactType,
                                                memo: String?,
                                                rates: ExchangeRates,
                                                memoIsShared: Bool,
                                                sharedPayload: SharedPayloadDTO) {

    permissionManager.requestPermission(for: .notification) { status in
      switch status {
      case .authorized:
        let completion = { [weak self] in
          guard let strongSelf = self else { return }
          viewController.dismiss(animated: true, completion: {
            strongSelf.analyticsManager.track(event: .paymentToPhoneNumber, with: nil)
            strongSelf.handleInvite(btcAmount: btcAmount, primaryCurrency: primaryCurrency, contact: contact,
                                    memo: memo, rates: rates, memoIsShared: memoIsShared, sharedPayload: sharedPayload)
          })
        }

        if contact.kind == .registeredUser {
          completion()

        } else {
          if self.persistenceManager.brokers.preferences.didOptOutOfInvitationPopup {
            completion()
          } else {
            self.showModalForInviteExplanation(with: viewController,
                                               phoneNumber: contact.displayIdentity,
                                               completion: completion)
          }
        }
      default:
        break
      }
    }
  }

  func viewController(_ viewController: UIViewController,
                      checkingVerificationStatusFor identityHash: String) -> Promise<[WalletAddressesQueryResponse]> {

    return self.networkManager.queryWalletAddresses(identityHashes: [identityHash])
  }

  private func trackTransactionType(with contact: ContactType?) {
    if contact != nil {
      analyticsManager.track(event: .paymentToContact, with: nil)
    } else {
      analyticsManager.track(event: .paymentToAddress, with: nil)
    }
  }

  func viewController(
    _ viewController: UIViewController,
    sendingMax txData: CNBTransactionData,
    address: String,
    contact: ContactType?,
    rates: ExchangeRates,
    sharedPayload: SharedPayloadDTO
    ) {

    trackTransactionType(with: contact)

    txData.paymentAddress = address

    var outgoingTransactionData = OutgoingTransactionData.emptyInstance()
    outgoingTransactionData.feeAmount = Int(txData.feeAmount)
    outgoingTransactionData.amount = Int(txData.amount)
    outgoingTransactionData = configureOutgoingTransactionData(
      with: outgoingTransactionData,
      address: address,
      contact: contact,
      rates: rates,
      sharedPayload: sharedPayload
    )

    viewController.dismiss(animated: true)
    let btcAmount = NSDecimalNumber(integerAmount: outgoingTransactionData.amount, currency: .BTC)

    guard let wmgr = walletManager else { return }
    let config = TransactionFeeConfig(prefs: self.persistenceManager.brokers.preferences)
    if config.adjustableFeesEnabled {
      networkManager.latestFees().compactMap { FeeRates(fees: $0) }
        .then { (feeRates: FeeRates) -> Promise<ConfirmTransactionFeeModel> in
          //Ignore the previously-generated send max transaction data, get it for all three fee types
          return self.adjustableFeeViewModelSendingMax(
            config: config,
            rates: feeRates,
            wmgr: wmgr,
            address: address)
            .map { .adjustable($0) }

        }
        .done { (feeModel: ConfirmTransactionFeeModel) in
          self.showConfirmPayment(
            with: outgoingTransactionData,
            btcAmount: btcAmount,
            address: address,
            contact: contact,
            primaryCurrency: .BTC,
            feeModel: feeModel,
            rates: rates
          )
        }
        .catch(on: .main) { [weak self] error in
          guard let strongSelf = self else { return }
          strongSelf.handleTransactionError(error)
      }

    } else {
      // Use the previously-generated send max transaction data
      let feeModel = ConfirmTransactionFeeModel.standard(txData)
      showConfirmPayment(
        with: outgoingTransactionData,
        btcAmount: btcAmount,
        address: address,
        contact: contact,
        primaryCurrency: .BTC,
        feeModel: feeModel,
        rates: rates
      )
    }
  }

  func viewControllerDidSendPayment(_ viewController: UIViewController,
                                    btcAmount: NSDecimalNumber,
                                    requiredFeeRate: Double?,
                                    primaryCurrency: CurrencyCode,
                                    address: String,
                                    contact: ContactType?,
                                    rates: ExchangeRates,
                                    sharedPayload: SharedPayloadDTO) {

    guard let wmgr = walletManager else { return }

    trackTransactionType(with: contact)

    // create outgoingTransactionData DTO to populate and pass along down the send flow
    var outgoingTransactionData = OutgoingTransactionData.emptyInstance()
    outgoingTransactionData.amount = btcAmount.asFractionalUnits(of: .BTC)
    outgoingTransactionData.requiredFeeRate = requiredFeeRate
    outgoingTransactionData = configureOutgoingTransactionData(
      with: outgoingTransactionData,
      address: address,
      contact: contact,
      rates: rates,
      sharedPayload: sharedPayload
    )

    viewController.dismiss(animated: true)
    networkManager.latestFees().compactMap { FeeRates(fees: $0) }
      .then { (rates: FeeRates) -> Promise<ConfirmTransactionFeeModel> in
        // Take rates, get fee config, and return a fee mode
        let config = TransactionFeeConfig(prefs: self.persistenceManager.brokers.preferences)

        if let requiredFeeRate = outgoingTransactionData.requiredFeeRate {
          return wmgr.transactionData(
            forPayment: btcAmount,
            to: address,
            withFeeRate: requiredFeeRate)
            .map { .required($0) }
        } else if config.adjustableFeesEnabled {
          return self.adjustableFeeViewModel(
            config: config,
            rates: rates,
            wmgr: wmgr,
            btcAmount: btcAmount,
            address: address)
            .map { .adjustable($0) }

        } else {
          let defaultFeeRate = rates.rate(forType: config.defaultFeeType)
          return wmgr.transactionData(
            forPayment: btcAmount,
            to: address,
            withFeeRate: defaultFeeRate)
            .map { .standard($0) }
        }
      }
      .done { (feeModel: ConfirmTransactionFeeModel) in
        self.showConfirmPayment(
          with: outgoingTransactionData,
          btcAmount: btcAmount,
          address: address,
          contact: contact,
          primaryCurrency: primaryCurrency,
          feeModel: feeModel,
          rates: rates
        )
      }
      .catch(on: .main) { [weak self] error in
        guard let strongSelf = self else { return }
        strongSelf.handleTransactionError(error)
    }
  }

  private func adjustableFeeViewModel(config: TransactionFeeConfig,
                                      rates: FeeRates,
                                      wmgr: WalletManagerType,
                                      btcAmount: NSDecimalNumber,
                                      address: String) -> Promise<AdjustableTransactionFeeViewModel> {
    let lowRate = rates.rate(forType: .cheap)
    let mediumRate = rates.rate(forType: .slow)
    let highRate = rates.rate(forType: .fast)

    return wmgr.transactionData(forPayment: btcAmount, to: address, withFeeRate: lowRate)
      .map { lowTxData -> AdjustableTransactionFeeViewModel in
        let maybeMediumTxData = wmgr.failableTransactionData(forPayment: btcAmount, to: address, withFeeRate: mediumRate)
        let maybeHighTxData = wmgr.failableTransactionData(forPayment: btcAmount, to: address, withFeeRate: highRate)
        return AdjustableTransactionFeeViewModel(preferredFeeType: config.defaultFeeType,
                                                 lowFeeTxData: lowTxData,
                                                 mediumFeeTxData: maybeMediumTxData,
                                                 highFeeTxData: maybeHighTxData)
    }
  }

  private func adjustableFeeViewModelSendingMax(config: TransactionFeeConfig,
                                                rates: FeeRates,
                                                wmgr: WalletManagerType,
                                                address: String) -> Promise<AdjustableTransactionFeeViewModel> {
    let lowRate = rates.rate(forType: .cheap)
    let mediumRate = rates.rate(forType: .slow)
    let highRate = rates.rate(forType: .fast)

    return wmgr.transactionDataSendingMax(to: address, withFeeRate: lowRate)
      .map { lowTxData -> AdjustableTransactionFeeViewModel in
        let maybeMediumTxData = wmgr.failableTransactionDataSendingMax(to: address, withFeeRate: mediumRate)
        let maybeHighTxData = wmgr.failableTransactionDataSendingMax(to: address, withFeeRate: highRate)
        return AdjustableTransactionFeeViewModel(preferredFeeType: config.defaultFeeType,
                                                 lowFeeTxData: lowTxData,
                                                 mediumFeeTxData: maybeMediumTxData,
                                                 highFeeTxData: maybeHighTxData)
    }
  }

  private func showConfirmPayment(with dto: OutgoingTransactionData,
                                  btcAmount: NSDecimalNumber,
                                  address: String?,
                                  contact: ContactType?,
                                  primaryCurrency: CurrencyCode,
                                  feeModel: ConfirmTransactionFeeModel,
                                  rates: ExchangeRates) {
    let viewModel = ConfirmPaymentViewModel(btcAmount: btcAmount,
                                            primaryCurrency: primaryCurrency,
                                            address: address,
                                            contact: contact,
                                            outgoingTransactionData: dto,
                                            rates: rates)

    let confirmPayVC = ConfirmPaymentViewController.newInstance(kind: .payment(viewModel),
                                                                feeModel: feeModel,
                                                                delegate: self)

    self.navigationController.present(confirmPayVC, animated: true)
  }

  private func configureOutgoingTransactionData(with dto: OutgoingTransactionData,
                                                address: String?,
                                                contact: ContactType?,
                                                rates: ExchangeRates,
                                                sharedPayload: SharedPayloadDTO
    ) -> OutgoingTransactionData {
    guard let wmgr = self.walletManager else { return dto }
    var copy = dto
    copy.dropBitType = contact?.dropBitType ?? .none
    if let innerContact = contact {
      copy.displayName = innerContact.displayName ?? ""
      copy.displayIdentity = innerContact.displayIdentity
      copy.identityHash = innerContact.identityHash
    }
    address.map { copy.destinationAddress = $0 }
    copy.sharedPayloadDTO = sharedPayload

    let context = persistenceManager.createBackgroundContext()
    context.performAndWait {
      if wmgr.createAddressDataSource().checkAddressExists(for: copy.destinationAddress, in: context) != nil {
        copy.sentToSelf = true
      }
    }

    return copy
  }

  private func handleInvite(btcAmount: NSDecimalNumber,
                            primaryCurrency: CurrencyCode,
                            contact: ContactType,
                            memo: String?,
                            rates: ExchangeRates,
                            memoIsShared: Bool,
                            sharedPayload: SharedPayloadDTO) {
    guard let wmgr = walletManager else { return }
    networkManager.latestFees().compactMap { FeeRates(fees: $0) }
      .then { (feeRates: FeeRates) -> Promise<ConfirmTransactionFeeModel> in
        let config = TransactionFeeConfig(prefs: self.persistenceManager.brokers.preferences)
        return self.adjustableFeeViewModel(
          config: config,
          rates: feeRates,
          wmgr: wmgr,
          btcAmount: btcAmount,
          address: "")
          .map { .adjustable($0) }
      }
      .done(on: .main) { (feeModel: ConfirmTransactionFeeModel) -> Void in
        let viewModel = ConfirmPaymentInviteViewModel(address: nil,
                                                      contact: contact,
                                                      btcAmount: btcAmount,
                                                      primaryCurrency: primaryCurrency,
                                                      rates: rates,
                                                      sharedPayloadDTO: sharedPayload)
        let confirmPayVC = ConfirmPaymentViewController.newInstance(kind: .invite(viewModel),
                                                                    feeModel: feeModel,
                                                                    delegate: self)
        self.navigationController.present(confirmPayVC, animated: true)
      }
      .catch(on: .main) { [weak self] error in
        guard let strongSelf = self else { return }
        strongSelf.handleTransactionError(error)
    }
  }

  private func handleTransactionError(_ error: Error) {
    log.error(error, message: nil)
    if let txError = error as? TransactionDataError {
      let messageDescription = txError.messageDescription
      let config = AlertActionConfiguration(title: "OK", style: .default, action: nil)
      let alert = self.alertManager.alert(withTitle: "", description: messageDescription, image: nil, style: .alert, actionConfigs: [config])
      self.navigationController.present(alert, animated: true, completion: nil)
    }
  }

  func viewControllerDidPressContacts(_ viewController: UIViewController & SelectedValidContactDelegate) {
    analyticsManager.track(event: .contactsButtonPressed, with: nil)
    let mainContext = persistenceManager.mainQueueContext()
    guard persistenceManager.brokers.user.userIsVerified(in: mainContext) else {
      showModalForPhoneVerification(with: viewController)
      return
    }

    // Only reload if the permission status changes
    let shouldReloadContactCache = permissionManager.permissionStatus(for: .contacts) != .authorized

    permissionManager.requestPermission(for: .contacts) { [weak self] status in
      guard let strongSelf = self else { return }

      switch status {
      case .authorized:
        if shouldReloadContactCache {
          strongSelf.alertManager.showActivityHUD(withStatus: "Loading Contacts")

          strongSelf.contactCacheDataWorker.reloadSystemContactsIfNeeded(force: false) { [weak self] error in
            if let err = error {
              log.error(err, message: "Error reloading contacts cache")
            }

            self?.alertManager.hideActivityHUD(withDelay: nil) {
              self?.presentContacts(mode: .contacts, selectionDelegate: viewController)
            }
          }

        } else {
          strongSelf.presentContacts(mode: .contacts, selectionDelegate: viewController)
        }

      default:
        break
      }
    }
  }

  private func presentContacts(mode: ContactsViewControllerMode, selectionDelegate viewController: SelectedValidContactDelegate) {
    let contactsViewController = ContactsViewController.newInstance(mode: mode,
                                                                    coordinationDelegate: self,
                                                                    selectionDelegate: viewController)
    self.navigationController.topViewController()?.present(contactsViewController, animated: true)
  }

  func viewControllerDidRequestVerificationCheck(_ viewController: UIViewController, completion: @escaping (() -> Void)) {
    guard launchStateManager.deviceIsVerified() else {
      showModalForPhoneVerification(with: viewController)
      return
    }

    completion()
  }

  private func showModalForInviteExplanation(with viewController: UIViewController, phoneNumber: String, completion: @escaping () -> Void) {
    let title = """
    \n We will send a DropBit to \n\(phoneNumber).
    Once DropBit is downloaded you will be notified and it will be executed. \n
    """
    let dontShowAction = AlertActionConfiguration(title: "Don't show this message again", style: .default) { [weak self] in
      guard let strongSelf = self else { return }
      strongSelf.persistenceManager.brokers.preferences.didOptOutOfInvitationPopup = true
      completion()
    }
    let okAction = AlertActionConfiguration(title: "OK", style: .default) {
      completion()
    }
    let configs = [dontShowAction, okAction]
    let alert = alertManager.alert(withTitle: title, description: nil, image: nil, style: .alert, buttonLayout: .vertical, actionConfigs: configs)
    viewController.present(alert, animated: true)
  }

  private func showModalForTwitterVerification(with viewController: UIViewController) {
    let title = "\n In order to use the send by Twitter feature you must verify with your Twitter account \n"
    showModalForMissingVerification(with: viewController, alertTitle: title, identityType: .twitter)
  }

  private func showModalForPhoneVerification(with viewController: UIViewController) {
    let title = "\n In order to use the send by SMS feature you must verify your phone \n"
    showModalForMissingVerification(with: viewController, alertTitle: title, identityType: .phone)
  }

  private func showModalForMissingVerification(with viewController: UIViewController,
                                               alertTitle: String,
                                               identityType: UserIdentityType) {
    let notNowAction = AlertActionConfiguration(title: "Not Now", style: .default, action: nil)
    let verifyAction = AlertActionConfiguration(title: "Verify", style: .default) { [weak self] in
      guard let strongSelf = self else { return }
      viewController.dismiss(animated: true, completion: {
        strongSelf.startDeviceVerificationFlow(userIdentityType: identityType, shouldOrphanRoot: false, selectedSetupFlow: nil)
      })
    }
    let configs = [notNowAction, verifyAction]
    let alert = alertManager.alert(withTitle: alertTitle, description: nil, image: nil, style: .alert, actionConfigs: configs)
    viewController.present(alert, animated: true)
  }

  func viewControllerDidPressScan(_ viewController: UIViewController, btcAmount: NSDecimalNumber, primaryCurrency: CurrencyCode) {
    analyticsManager.track(event: .scanButtonPressed, with: nil)
    viewController.dismiss(animated: true) { [weak self] in
      self?.showScanViewController(fallbackBTCAmount: btcAmount, primaryCurrency: primaryCurrency)
    }
  }

  func viewControllerDidAttemptInvalidDestination(_ viewController: UIViewController, error: Error?) {
    guard let err = error else { return }

    let generalMessage = "Invalid bitcoin address or phone number."
    var fullMessage = ""

    if let parsingError = err as? CKRecipientParserError {
      fullMessage = "\(parsingError.localizedDescription)"

    } else if let validationError = err as? ValidatorTypeError,
      let message = validationError.displayMessage {
      fullMessage = message

    } else {
      fullMessage = "\(generalMessage) \(err.localizedDescription)."
    }

    alertManager.showError(message: fullMessage, forDuration: 3.5)
  }

  func viewControllerDidSelectMemoButton(_ viewController: UIViewController, memo: String?, completion: @escaping (String) -> Void) {
    let memoViewController = MemoEntryViewController.makeFromStoryboard()
    memoViewController.backgroundImage = UIApplication.shared.screenshot()
    assignCoordinationDelegate(to: memoViewController)
    memoViewController.completion = completion
    memoViewController.memo = memo ?? ""
    viewController.present(memoViewController, animated: true)
  }

  func viewControllerShouldInitiallyAllowMemoSharing(_ viewController: SendPaymentViewController) -> Bool {
    let context = persistenceManager.mainQueueContext()
    return persistenceManager.brokers.user.userIsVerified(in: context)
  }

  func deviceCountryCode() -> Int? {
    return persistenceManager.deviceCountryCode()
  }

  func viewController(_ viewController: UIViewController,
                      checkForContactFromGenericContact genericContact: GenericContact,
                      completion: @escaping ((ValidatedContact?) -> Void)) {
    self.contactCacheDataWorker.refreshStatus(forPhoneNumber: genericContact.globalPhoneNumber,
                                              completion: completion)
  }

  func viewController(_ viewController: UIViewController,
                      checkForVerifiedTwitterContact twitterContact: TwitterContactType) -> Promise<TwitterContactType> {
    return self.networkManager.queryUsers(identityHashes: [twitterContact.identityHash])
      .then { (response: StringDictResponse) -> Promise<TwitterContactType> in
        let statusString = response[twitterContact.identityHash] ?? ""
        let status = UserIdentityVerificationStatus.case(forString: statusString) ?? .notVerified
        var contact = twitterContact
        switch status {
        case .verified:
          contact.kind = .registeredUser
          return Promise.value(contact)
        case .notVerified:
          contact.kind = .invite
          return Promise.value(contact)
        }
      }
  }

  func viewController(
    _ viewController: UIViewController,
    sendMaxFundsTo address: String,
    feeRate: Double) -> Promise<CNBTransactionData> {
    guard let wmgr = walletManager else { return Promise(error: CKPersistenceError.noManagedWallet) }
    let data = wmgr.transactionDataSendingMax(to: address, withFeeRate: feeRate)
    return data
  }

  func usableFeeRate(from feeRates: Fees) -> Double? {
    if adjustableFeesIsEnabled {
      switch preferredTransactionFeeMode {
      case .fast: return feeAboveMin(from: feeRates[.best])
      case .slow: return feeAboveMin(from: feeRates[.better])
      case .cheap: return feeAboveMin(from: feeRates[.good])
      }
    } else {
      return feeRates[.best]
    }
  }

  private func feeAboveMin(from feeRate: Double?) -> Double? {
    let uintFee = feeRate.flatMap { self.walletManager?.usableFeeRate(from: $0) }
    let usableFee = uintFee.flatMap { Int($0) }.flatMap { Double($0) }
    return usableFee
  }
}
