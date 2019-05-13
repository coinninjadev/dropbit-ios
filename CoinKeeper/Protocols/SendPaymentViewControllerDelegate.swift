//
//  SendPaymentViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import PromiseKit
import enum Result.Result

protocol SendPaymentViewControllerDelegate: DeviceCountryCodeProvider {
  func sendPaymentViewControllerDidLoad(_ viewController: UIViewController)
  func viewControllerDidPressScan(_ viewController: UIViewController, btcAmount: NSDecimalNumber, primaryCurrency: CurrencyCode)
  func viewControllerDidPressContacts(_ viewController: UIViewController & SelectedValidContactDelegate)
  func viewControllerDidPressTwitter(_ viewController: UIViewController & SelectedValidContactDelegate)
  func viewController(_ viewController: UIViewController,
                      checkingCachedAddressesFor phoneNumberHash: String,
                      completion: @escaping (Result<[WalletAddressesQueryResponse], UserProviderError>) -> Void)

  /**
   Dismisses `viewController` and shows phone verification flow if they haven't yet verified, otherwise calls `completion`.
   */
  func viewControllerDidRequestVerificationCheck(_ viewController: UIViewController, completion: @escaping (() -> Void))
  func viewController(_ viewController: UIViewController,
                      sendingMax data: CNBTransactionData,
                      address: String,
                      contact: ContactType?,
                      rates: ExchangeRates,
                      sharedPayload: SharedPayloadDTO)
  func viewControllerDidSendPayment(_ viewController: UIViewController,
                                    btcAmount: NSDecimalNumber,
                                    requiredFeeRate: Double?,
                                    primaryCurrency: CurrencyCode,
                                    address: String,
                                    contact: ContactType?,
                                    rates: ExchangeRates,
                                    sharedPayload: SharedPayloadDTO)

  /// An address negotiation applies to both new user invites and registered users without addresses on the server
  func viewControllerDidBeginAddressNegotiation(_ viewController: UIViewController,
                                                btcAmount: NSDecimalNumber,
                                                primaryCurrency: CurrencyCode,
                                                contact: ContactType,
                                                memo: String?,
                                                rates: ExchangeRates,
                                                memoIsShared: Bool,
                                                sharedPayload: SharedPayloadDTO)

  func viewControllerDidAttemptInvalidDestination(_ viewController: UIViewController, error: Error?)
  func viewControllerDidSelectPaste(_ viewController: UIViewController)
  func viewControllerDidSelectMemoButton(_ viewController: UIViewController, memo: String?, completion: @escaping (String) -> Void)
  func viewControllerDidRequestAlert(_ viewController: UIViewController, viewModel: AlertControllerViewModel)
  func viewControllerShouldInitiallyAllowMemoSharing(_ viewController: SendPaymentViewController) -> Bool
  func showAlertForInvalidContactOrPhoneNumber(contactName: String?, displayNumber: String)

  func viewController(_ viewController: UIViewController,
                      checkForContactFromGenericContact genericContact: GenericContact,
                      completion: @escaping ((ValidatedContact?) -> Void))

  func viewController(
    _ viewController: UIViewController,
    sendMaxFundsTo address: String,
    feeRate: Double
  ) -> Promise<CNBTransactionData>
}
