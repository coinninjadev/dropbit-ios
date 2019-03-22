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
import os.log

extension AppCoordinator: SendPaymentViewControllerDelegate {
  private var logger: OSLog {
    return OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "send_payment_delegate")
  }

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
          let popupString = self.persistenceManager.string(for: .invitationPopup) ?? ""
          if let value = CKUserDefaults.Value(rawValue: popupString), case .optOut = value {
            completion()
          } else {
            self.showModalForInviteExplanation(with: viewController,
                                               phoneNumber: contact.displayNumber,
                                               completion: completion)
          }
        }
      default:
        break
      }
    }
  }

  func viewController(_ viewController: UIViewController,
                      checkingCachedAddressesFor phoneNumberHash: String,
                      completion: @escaping (Result<[WalletAddressesQueryResponse], UserProviderError>) -> Void) {
    let bgContext = persistenceManager.createBackgroundContext()
    bgContext.perform {
      self.networkManager.queryWalletAddresses(phoneNumberHashes: [phoneNumberHash])
        .done(on: .main) { response in
          completion(.success(response))
        }.catch(on: .main) { error in
          os_log("failed to request address for phone hash: %{private}@.\n%@",
                 log: self.logger, type: .error, phoneNumberHash, error.localizedDescription)
          completion(.failure(.noData))
      }
    }
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
    sendingMax data: CNBTransactionData,
    address: String?,
    contact: ContactType?,
    rates: ExchangeRates,
    sharedPayload: SharedPayloadDTO
    ) {

    trackTransactionType(with: contact)

    var outgoingTransactionData = OutgoingTransactionData.emptyInstance()
    outgoingTransactionData.feeAmount = Int(data.feeAmount)
    outgoingTransactionData.amount = Int(data.amount)//.asNSDecimalNumber.asFractionalUnits(of: .BTC)
    outgoingTransactionData = configureOutgoingTransactionData(
      with: outgoingTransactionData,
      address: address,
      contact: contact,
      rates: rates,
      sharedPayload: sharedPayload
    )

    viewController.dismiss(animated: true)

    showConfirmPayment(
      with: outgoingTransactionData,
      btcAmount: .zero,
      address: address,
      contact: contact,
      primaryCurrency: .BTC,
      transactionData: data,
      rates: rates
    )
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
    outgoingTransactionData.requiredFeeRate = requiredFeeRate
    outgoingTransactionData = configureOutgoingTransactionData(
      with: outgoingTransactionData,
      address: address,
      contact: contact,
      rates: rates,
      sharedPayload: sharedPayload
    )

    viewController.dismiss(animated: true)
    networkManager.latestFees()
      .compactMap { $0[.good] }
      .then { (networkFeeRate: Double) -> Promise<CNBTransactionData> in
        let relevantFeeRate = outgoingTransactionData.requiredFeeRate ?? networkFeeRate
        return wmgr.transactionData(
          forPayment: btcAmount,
          to: address,
          withFeeRate: relevantFeeRate
        )
      }
      .done { (transactionData: CNBTransactionData) in
        self.showConfirmPayment(
          with: outgoingTransactionData,
          btcAmount: btcAmount,
          address: address,
          contact: contact,
          primaryCurrency: primaryCurrency,
          transactionData: transactionData,
          rates: rates
        )
      }
      .catch(on: .main) { [weak self] error in
        guard let strongSelf = self else { return }
        strongSelf.handleTransactionError(error)
    }
  }

  private func showConfirmPayment(with dto: OutgoingTransactionData,
                                  btcAmount: NSDecimalNumber,
                                  address: String?,
                                  contact: ContactType?,
                                  primaryCurrency: CurrencyCode,
                                  transactionData: CNBTransactionData,
                                  rates: ExchangeRates) {
    let confirmPayVC = ConfirmPaymentViewController.makeFromStoryboard()
    self.assignCoordinationDelegate(to: confirmPayVC)
    let viewModel = ConfirmPaymentViewModel(
      btcAmount: btcAmount,
      primaryCurrency: primaryCurrency,
      address: address,
      contact: contact,
      fee: Int(transactionData.feeAmount),
      outgoingTransactionData: dto,
      transactionData: transactionData,
      rates: rates)
    confirmPayVC.kind = .payment(viewModel)
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
    contact.map { innerContact in
      copy.contactName = innerContact.displayName ?? ""
      copy.contactPhoneNumber = innerContact.globalPhoneNumber
      copy.contactPhoneNumberHash = innerContact.phoneNumberHash
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
    networkManager.latestFees()
      .compactMap { $0[.good] }
      .then { (feeRate: Double) -> Promise<CNBTransactionData> in
        return wmgr.transactionData(
          forPayment: btcAmount,
          to: "",
          withFeeRate: feeRate
        )
      }
      .done(on: .main) { (transactionData: CNBTransactionData) -> Void in
        let viewModel = ConfirmPaymentInviteViewModel(
          address: nil,
          contact: contact,
          btcAmount: btcAmount,
          primaryCurrency: primaryCurrency,
          fee: max(Int(transactionData.feeAmount), 1),
          rates: rates,
          sharedPayloadDTO: sharedPayload
        )
        let confirmPayVC = ConfirmPaymentViewController.makeFromStoryboard()
        self.assignCoordinationDelegate(to: confirmPayVC)

        confirmPayVC.kind = .invite(viewModel)
        self.navigationController.present(confirmPayVC, animated: true)
      }
      .catch(on: .main) { [weak self] error in
        guard let strongSelf = self else { return }
        strongSelf.handleTransactionError(error)
    }
  }

  private func handleTransactionError(_ error: Error) {
    os_log("error in %@.\n%@", log: logger, type: .error, #function, error.localizedDescription)
    if let txError = error as? TransactionDataError {
      let messageDescription = txError.messageDescription
      let config = AlertActionConfiguration(title: "OK", style: .default, action: nil)
      let alert = self.alertManager.alert(withTitle: "", description: messageDescription, image: nil, style: .alert, actionConfigs: [config])
      self.navigationController.present(alert, animated: true, completion: nil)
    }
  }

  func viewControllerDidPressContacts(_ viewController: UIViewController & SelectedValidContactDelegate) {
    analyticsManager.track(event: .contactsButtonPressed, with: nil)
    guard launchStateManager.deviceIsVerified() else {
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

          strongSelf.contactCacheDataWorker.reloadSystemContactsIfNeeded { [weak self] error in
            if let err = error, let self = self {
              os_log("Error reloading contacts cache: %@", log: self.logger, type: .error, err.localizedDescription)
            }

            self?.alertManager.hideActivityHUD(withDelay: nil) {
              self?.presentContacts(selectionDelegate: viewController)
            }
          }

        } else {
          strongSelf.presentContacts(selectionDelegate: viewController)
        }

      default:
        break
      }
    }
  }

  private func presentContacts(selectionDelegate viewController: SelectedValidContactDelegate) {
    let contactsViewController = ContactsViewController.makeFromStoryboard()
    contactsViewController.selectionDelegate = viewController
    self.assignCoordinationDelegate(to: contactsViewController)
    contactsViewController.modalPresentationStyle = .overFullScreen
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
    \n We will send a DropBit to \(phoneNumber).
    Once DropBit is downloaded you will be notified and it will be executed. \n
    """
    let dontShowAction = AlertActionConfiguration(title: "Don't show this message again", style: .default) { [weak self] in
      guard let strongSelf = self else { return }
      strongSelf.persistenceManager.set(.optOut, for: .invitationPopup)
      completion()
    }
    let okAction = AlertActionConfiguration(title: "Ok", style: .default) {
      completion()
    }
    let configs = [dontShowAction, okAction]
    let alert = alertManager.alert(withTitle: title, description: nil, image: nil, style: .alert, buttonLayout: .vertical, actionConfigs: configs)
    viewController.present(alert, animated: true)
  }

  private func showModalForPhoneVerification(with viewController: UIViewController) {
    let title = "\n In order to use the send by SMS feature you must verify your phone \n"
    let notNowAction = AlertActionConfiguration(title: "Not Now", style: .default, action: nil)
    let verifyAction = AlertActionConfiguration(title: "Verify", style: .default) { [weak self] in
      guard let strongSelf = self else { return }
      viewController.dismiss(animated: true, completion: {
        strongSelf.navigationController.isNavigationBarHidden = false
        strongSelf.startDeviceVerificationFlow(shouldOrphanRoot: false)
      })
    }
    let configs = [notNowAction, verifyAction]
    let alert = alertManager.alert(withTitle: title, description: nil, image: nil, style: .alert, actionConfigs: configs)
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
    return persistenceManager.userIsVerified(in: context)
  }

  func deviceCountryCode() -> Int? {
    return persistenceManager.deviceCountryCode()
  }

  func viewController(_ viewController: UIViewController, checkForContactFromGenericContact genericContact: GenericContact) -> ValidatedContact? {
    let globalPhoneNumber = genericContact.globalPhoneNumber
    let context = contactCacheManager.mainQueueContext
    var validatedContact: ValidatedContact?
    context.performAndWait {
      let foundContact = contactCacheManager.validatedMetadata(for: globalPhoneNumber, in: context)?.cachedPhoneNumber
      validatedContact = foundContact.flatMap { ValidatedContact(cachedNumber: $0) }
    }
    return validatedContact
  }

  func viewController(
    _ viewController: UIViewController,
    sendMaxFundsTo address: String,
    feeRate: Double) -> Promise<CNBTransactionData> {
    guard let wmgr = walletManager else { return Promise(error: CKPersistenceError.noManagedWallet) }
    let data = wmgr.transactionDataSendingMax(to: address, withFeeRate: feeRate)
    return data
  }
}
