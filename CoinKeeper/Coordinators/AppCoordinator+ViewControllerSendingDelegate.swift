//
//  AppCoordinator+ViewControllerSendingDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 7/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import Foundation
import PromiseKit
import Permission
import UIKit

extension AppCoordinator: ViewControllerSendingDelegate {

  func viewController(
    _ viewController: UIViewController,
    sendMaxFundsTo address: String,
    feeRate: Double) -> Promise<CNBTransactionData> {
    guard let wmgr = walletManager else { return Promise(error: CKPersistenceError.noManagedWallet) }
    let data = wmgr.transactionDataSendingMax(to: address, withFeeRate: feeRate)
    return data
  }

  func viewController(
    _ viewController: UIViewController,
    sendingMax txData: CNBTransactionData,
    address: String,
    walletType: WalletType,
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
    let currencyPair = CurrencyPair(btcPrimaryWith: self.currencyController)

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
            walletType: walletType,
            contact: contact,
            currencyPair: currencyPair,
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
        walletType: walletType,
        contact: contact,
        currencyPair: currencyPair,
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
                                    walletType: WalletType,
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
    let currencyPair = CurrencyPair(primary: primaryCurrency, fiat: self.currencyController.fiatCurrency)

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
          walletType: walletType,
          contact: contact,
          currencyPair: currencyPair,
          feeModel: feeModel,
          rates: rates
        )
      }
      .catch(on: .main) { [weak self] error in
        guard let strongSelf = self else { return }
        strongSelf.handleTransactionError(error)
    }
  }

  func viewControllerDidBeginAddressNegotiation(_ viewController: UIViewController,
                                                btcAmount: NSDecimalNumber,
                                                primaryCurrency: CurrencyCode,
                                                contact: ContactType,
                                                memo: String?,
                                                walletType: WalletType,
                                                rates: ExchangeRates,
                                                memoIsShared: Bool,
                                                sharedPayload: SharedPayloadDTO) {

    permissionManager.requestPermission(for: .notification) { status in
      switch status {
      case .authorized:
        let completion = { [weak self] in
          guard let self = self else { return }
          viewController.dismiss(animated: true, completion: {
            self.analyticsManager.track(event: .paymentToPhoneNumber, with: nil)
            let currencyPair = CurrencyPair(primary: primaryCurrency, fiat: self.currencyController.fiatCurrency)
            self.handleInvite(btcAmount: btcAmount, currencyPair: currencyPair, contact: contact, memo: memo,
                              walletType: walletType, rates: rates, memoIsShared: memoIsShared, sharedPayload: sharedPayload)
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
      case .denied, .disabled:
        let alertViewModel = self.notificationSettingsAlertViewModel(for: status)
        self.viewControllerDidRequestAlert(viewController, viewModel: alertViewModel)

      case .notDetermined:
        log.error("Reached notDetermined status after requesting notification permission")
      }
    }
  }

  func notificationSettingsAlertViewModel(for status: PermissionStatus) -> AlertControllerViewModel {
    let title = "Permission for Notifications was \(status.rawValue)"
    let message = """
        Push notifications are an important part of the DropBit experience.
        Without them you will not be notified to complete transactions which will cause them to expire.
        \nPlease enable notifications for DropBit in iOS Settings.
        """
    let alertActions: [AlertActionConfiguration] = [
      AlertActionConfiguration(title: "Cancel", style: .cancel, action: nil),
      AlertActionConfiguration(title: "Settings", style: .default, action: {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
      })
    ]

    return AlertControllerViewModel(title: title, description: message, image: nil, style: .alert, actions: alertActions)
  }

  // MARK: - Helper Methods

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

  private func showConfirmPayment(with dto: OutgoingTransactionData,
                                  btcAmount: NSDecimalNumber,
                                  address: String?,
                                  walletType: WalletType,
                                  contact: ContactType?,
                                  currencyPair: CurrencyPair,
                                  feeModel: ConfirmTransactionFeeModel,
                                  rates: ExchangeRates) {

    let isLightningConvertible = true //TODO

    let displayLightningPaymentViewController: () -> Void = {}

    let displayConfirmPaymentViewController: () -> Void = {
      let viewModel = ConfirmPaymentViewModel(address: address,
                                              contact: contact,
                                              walletType: walletType,
                                              btcAmount: btcAmount,
                                              currencyPair: currencyPair,
                                              exchangeRates: rates,
                                              outgoingTransactionData: dto)

      let confirmPayVC = ConfirmPaymentViewController.newInstance(type: .payment,
                                                                  viewModel: viewModel,
                                                                  feeModel: feeModel,
                                                                  delegate: self)

      self.navigationController.present(confirmPayVC, animated: true)
    }

    if isLightningConvertible {
      let tryLightningViewController = TryLightningViewController.newInstance(yesCompletionHandler: displayLightningPaymentViewController,
                                                                              noCompletionHandler: displayConfirmPaymentViewController)
      navigationController.present(tryLightningViewController, animated: true)
    } else {
      displayConfirmPaymentViewController()
    }

  }

  struct UsableFeeRates {
    let lowRate: Double
    let mediumRate: Double
    let highRate: Double

    init(rates: FeeRates, walletManager: WalletManagerType) {
      let low = rates.rate(forType: .cheap)
      let medium = rates.rate(forType: .slow)
      let high = rates.rate(forType: .fast)
      self.lowRate = Double(walletManager.usableFeeRate(from: low))
      self.mediumRate = Double(walletManager.usableFeeRate(from: medium))
      self.highRate = Double(walletManager.usableFeeRate(from: high))
    }
  }

  private func adjustableFeeViewModel(config: TransactionFeeConfig,
                                      rates: FeeRates,
                                      wmgr: WalletManagerType,
                                      btcAmount: NSDecimalNumber,
                                      address: String) -> Promise<AdjustableTransactionFeeViewModel> {
    let usableRates = UsableFeeRates(rates: rates, walletManager: wmgr)

    return wmgr.transactionData(forPayment: btcAmount, to: address, withFeeRate: usableRates.lowRate)
      .map { lowTxData -> AdjustableTransactionFeeViewModel in
        let maybeMediumTxData = wmgr.failableTransactionData(forPayment: btcAmount, to: address, withFeeRate: usableRates.mediumRate)
        let maybeHighTxData = wmgr.failableTransactionData(forPayment: btcAmount, to: address, withFeeRate: usableRates.highRate)
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
    let usableRates = UsableFeeRates(rates: rates, walletManager: wmgr)

    return wmgr.transactionDataSendingMax(to: address, withFeeRate: usableRates.lowRate)
      .map { lowTxData -> AdjustableTransactionFeeViewModel in
        let maybeMediumTxData = wmgr.failableTransactionDataSendingMax(to: address, withFeeRate: usableRates.mediumRate)
        let maybeHighTxData = wmgr.failableTransactionDataSendingMax(to: address, withFeeRate: usableRates.highRate)
        return AdjustableTransactionFeeViewModel(preferredFeeType: config.defaultFeeType,
                                                 lowFeeTxData: lowTxData,
                                                 mediumFeeTxData: maybeMediumTxData,
                                                 highFeeTxData: maybeHighTxData)
    }
  }

  private func handleInvite(btcAmount: NSDecimalNumber,
                            currencyPair: CurrencyPair,
                            contact: ContactType,
                            memo: String?,
                            walletType: WalletType,
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

        let isLightningConvertible = true //TODO

        let displayLightningPaymentViewController: () -> Void = {}

        let displayConfirmPaymentViewController: () -> Void = {
          let viewModel = ConfirmPaymentInviteViewModel(address: nil,
                                                        contact: contact,
                                                        walletType: walletType,
                                                        btcAmount: btcAmount,
                                                        currencyPair: currencyPair,
                                                        exchangeRates: rates,
                                                        sharedPayloadDTO: sharedPayload)
          let confirmPayVC = ConfirmPaymentViewController.newInstance(type: .invite,
                                                                      viewModel: viewModel,
                                                                      feeModel: feeModel,
                                                                      delegate: self)
          self.navigationController.present(confirmPayVC, animated: true)
        }

        if isLightningConvertible {
          let tryLightningViewController = TryLightningViewController.newInstance(yesCompletionHandler: displayLightningPaymentViewController,
                                                                                  noCompletionHandler: displayConfirmPaymentViewController)
          self.navigationController.present(tryLightningViewController, animated: true)
        } else {
          displayConfirmPaymentViewController()
        }
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

  private func trackTransactionType(with contact: ContactType?) {
    if contact != nil {
      analyticsManager.track(event: .paymentToContact, with: nil)
    } else {
      analyticsManager.track(event: .paymentToAddress, with: nil)
    }
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

}
