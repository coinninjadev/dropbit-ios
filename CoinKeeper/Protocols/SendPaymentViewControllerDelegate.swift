//
//  SendPaymentViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 6/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Cnlib
import PromiseKit
import enum Result.Result
import UIKit

struct SendingDelegateInputs {
  let primaryCurrency: CurrencyCode
  let walletTxType: WalletTransactionType
  let contact: ContactType?
  let rates: ExchangeRates
  let sharedPayload: SharedPayloadDTO
  let rbfReplaceabilityOption: RBFOption

  init(primaryCurrency: CurrencyCode,
       walletTxType: WalletTransactionType,
       contact: ContactType?,
       rates: ExchangeRates,
       sharedPayload: SharedPayloadDTO,
       rbfReplaceabilityOption: RBFOption) {
    self.primaryCurrency = primaryCurrency
    self.walletTxType = walletTxType
    self.contact = contact
    self.rates = rates
    self.sharedPayload = sharedPayload
    self.rbfReplaceabilityOption = rbfReplaceabilityOption
  }

  init(sendPaymentVM vm: SendPaymentViewModel,
       contact: ContactType?,
       payloadDTO: SharedPayloadDTO,
       rbfReplaceabilityOption: RBFOption = .allowed) {
    self.init(primaryCurrency: vm.primaryCurrency,
              walletTxType: vm.walletTransactionType,
              contact: contact,
              rates: vm.exchangeRates,
              sharedPayload: payloadDTO,
              rbfReplaceabilityOption: rbfReplaceabilityOption)
  }

}

struct SendOnChainPaymentInputs {
  let networkManager: NetworkManagerType
  let wmgr: WalletManagerType
  let outgoingTxData: OutgoingTransactionData
  let btcAmount: NSDecimalNumber
  let address: String
  let contact: ContactType?
  let currencyPair: CurrencyPair
  let exchangeRates: ExchangeRates
  let rbfReplaceabilityOption: RBFOption
}

protocol SendPaymentViewControllerRoutingDelegate: PaymentBuildingDelegate {

  func viewController(_ viewController: UIViewController,
                      sendingMax data: CNBCnlibTransactionData,
                      to address: String,
                      inputs: SendingDelegateInputs)

  func viewControllerDidSendPayment(_ viewController: UIViewController,
                                    btcAmount: NSDecimalNumber,
                                    requiredFeeRate: Double?,
                                    paymentTarget: String,
                                    inputs: SendingDelegateInputs)

  /// An address negotiation applies to both new user invites and registered users without addresses on the server
  func viewControllerDidBeginAddressNegotiation(_ viewController: UIViewController,
                                                btcAmount: NSDecimalNumber,
                                                inputs: SendingDelegateInputs)

}

protocol SendPaymentViewControllerDelegate: SendPaymentViewControllerRoutingDelegate, DeviceCountryCodeProvider {
  func sendPaymentViewControllerDidLoad(_ viewController: UIViewController)
  func sendPaymentViewControllerWillDismiss(_ viewController: UIViewController)
  func viewControllerDidPressScan(_ viewController: UIViewController, btcAmount: NSDecimalNumber, primaryCurrency: CurrencyCode)
  func viewControllerDidPressContacts(_ viewController: UIViewController & SelectedValidContactDelegate)
  func viewControllerDidPressTwitter(_ viewController: UIViewController & SelectedValidContactDelegate)
  func viewControllerDidRequestRegisteredAddress(_ viewController: UIViewController,
                                                 ofType addressType: WalletAddressType,
                                                 forIdentity identityHash: String) -> Promise<[WalletAddressesQueryResponse]>

  /**
   Dismisses `viewController` and shows phone verification flow if they haven't yet verified, otherwise calls `completion`.
   */
  func viewControllerDidRequestVerificationCheck(_ viewController: UIViewController, completion: @escaping CKCompletion)

  func viewControllerDidAttemptInvalidDestination(_ viewController: UIViewController, error: Error?)
  func viewControllerDidSelectPaste(_ viewController: UIViewController)
  func viewControllerDidSelectMemoButton(_ viewController: UIViewController, memo: String?, completion: @escaping (String) -> Void)
  func viewControllerDidRequestAlert(_ viewController: UIViewController, viewModel: AlertControllerViewModel)
  func viewControllerShouldInitiallyAllowMemoSharing(_ viewController: SendPaymentViewController) -> Bool
  func showAlertForInvalidContactOrPhoneNumber(contactName: String?, displayNumber: String)

  func viewController(_ viewController: UIViewController,
                      checkForContactFromGenericContact genericContact: GenericContact,
                      completion: @escaping ((ValidatedContact?) -> Void))

  func viewController(_ viewController: UIViewController,
                      checkForVerifiedTwitterContact twitterContact: TwitterContactType) -> Promise<TwitterContactType>

  func usableFeeRate(from feeRates: Fees) -> Double?
  func viewControllerDidReceiveLightningURLToDecode(_ lightningUrl: LightningURL) -> Promise<LNDecodePaymentRequestResponse>
}
