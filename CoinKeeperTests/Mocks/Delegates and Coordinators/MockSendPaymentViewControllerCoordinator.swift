//
//  MockSendPaymentViewControllerCoordinator.swift
//  DropBitTests
//
//  Created by Ben Winters on 11/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit
import CNBitcoinKit
@testable import DropBit

class MockSendPaymentViewControllerCoordinator: SendPaymentViewControllerCoordinator {

  var networkManager: NetworkManagerType
  var balanceUpdateManager: BalanceUpdateManager

  init(balanceUpdateManager: BalanceUpdateManager = BalanceUpdateManager(),
       networkManager: NetworkManagerType) {
    self.balanceUpdateManager = balanceUpdateManager
    self.networkManager = networkManager
  }

  func viewControllerDidSelectCloseWithToggle(_ viewController: UIViewController) { }

  func sendMaxFundsTo(address destinationAddress: String,
                      feeRate: Double) -> Promise<CNBTransactionData> {
    return Promise { _ in }
  }

  func configureOutgoingTransactionData(with dto: OutgoingTransactionData,
                                        address: String?,
                                        inputs: SendingDelegateInputs) -> OutgoingTransactionData {
    return OutgoingTransactionData.emptyInstance()
  }

  func buildNonReplaceableTransactionData(
    btcAmount: NSDecimalNumber,
    address: String,
    exchangeRates: ExchangeRates) -> PaymentData? {
    return nil
  }

  func sendPaymentViewControllerWillDismiss(_ viewController: UIViewController) {
    didTapClose = true
  }

  func deviceCountryCode() -> Int? {
    return nil
  }

  func showAlertForInvalidContactOrPhoneNumber(contactName: String?, displayNumber: String) {
  }

  func viewController(_ viewController: UIViewController, checkForContactFromGenericContact genericContact: GenericContact) -> ValidatedContact? {
    return nil
  }

  var fakeTransactionData: CNBTransactionData?
  var didAskToSendMaxFunds = false
  func viewController(_ viewController: UIViewController, sendMaxFundsTo address: String, feeRate: Double) -> Promise<CNBTransactionData> {
    didAskToSendMaxFunds = true
    if let data = fakeTransactionData {
      return Promise.value(data)
    } else {
      return Promise(error: TransactionDataError.insufficientFunds)
    }
  }

  func balanceNetPending() -> WalletBalances {
    return WalletBalances(onChain: .zero, lightning: .zero)
  }

  func spendableBalanceNetPending() -> WalletBalances {
    return WalletBalances(onChain: .zero, lightning: .zero)
  }

  func latestExchangeRates(responseHandler: (ExchangeRates) -> Void) { }

  func latestFees() -> Promise<Fees> {
    return Promise.value([:])
  }

  var didTapTwitter = false
  func viewControllerDidPressTwitter(_ viewController: UIViewController & SelectedValidContactDelegate) {
    didTapTwitter = true
  }

  var didTapScan = false
  func viewControllerDidPressScan(_ viewController: UIViewController, btcAmount: NSDecimalNumber, primaryCurrency: CurrencyCode) {
    didTapScan = true
  }

  var didTapContacts = false
  func viewControllerDidPressContacts(_ viewController: UIViewController & SelectedValidContactDelegate) {
    didTapContacts = true
  }

  func viewController(
    _ viewController: UIViewController,
    sendingMax data: CNBTransactionData,
    to address: String,
    inputs: SendingDelegateInputs) { }

  func viewControllerDidRequestRegisteredAddress(
    _ viewController: UIViewController,
    ofType addressType: WalletAddressType,
    forIdentity identityHash: String) -> Promise<[WalletAddressesQueryResponse]> {
    return Promise { _ in }
  }

  func viewController(
    _ viewController: UIViewController,
    checkForVerifiedTwitterContact twitterContact: TwitterContactType) -> Promise<TwitterContactType> {
    return Promise { _ in }
  }

  func viewControllerDidRequestVerificationCheck(_ viewController: UIViewController, completion: @escaping CKCompletion) { }

  func viewControllerDidRequestAlert(_ viewController: UIViewController, viewModel: AlertControllerViewModel) { }

  func viewControllerShouldInitiallyAllowMemoSharing(_ viewController: SendPaymentViewController) -> Bool {
    return true
  }

  var didTapClose = false
  func viewControllerDidSelectClose(_ viewController: UIViewController) {
    didTapClose = true
  }

  var didTryDecode = false
  func viewControllerDidReceiveLightningURLToDecode(_ lightningUrl: LightningURL) -> Promise<LNDecodePaymentRequestResponse> {
    didTryDecode = true
    return Promise { _ in }
  }

  func viewControllerDidSelectClose(_ viewController: UIViewController, completion: CKCompletion? ) {
    didTapClose = true
  }

  func viewControllerDidSendPayment(_ viewController: UIViewController,
                                    btcAmount: NSDecimalNumber,
                                    requiredFeeRate: Double?,
                                    paymentTarget: String,
                                    inputs: SendingDelegateInputs) { }

  func viewControllerDidBeginAddressNegotiation(
    _ viewController: UIViewController,
    btcAmount: NSDecimalNumber,
    memo: String?,
    memoIsShared: Bool,
    inputs: SendingDelegateInputs) { }

  func viewController(_ viewController: UIViewController,
                      checkForContactFromGenericContact genericContact: GenericContact,
                      completion: @escaping ((ValidatedContact?) -> Void)) {
    completion(nil)
  }

  func sendPaymentViewControllerDidLoad(_ viewController: UIViewController) { }

  func viewControllerDidAttemptInvalidDestination(_ viewController: UIViewController, error: Error?) { }

  var didSelectMemoButton = false
  func viewControllerDidSelectMemoButton(_ viewController: UIViewController, memo: String?, completion: @escaping (String) -> Void) {
    didSelectMemoButton = true
  }

  var didTapPaste = false
  func viewControllerDidSelectPaste(_ viewController: UIViewController) {
    didTapPaste = true
  }

  func openURL(_ url: URL, completionHandler completion: CKCompletion?) { }
  func openURLExternally(_ url: URL, completionHandler completion: ((Bool) -> Void)?) { }

  func usableFeeRate(from feeRates: Fees) -> Double? {
    return nil
  }
}
