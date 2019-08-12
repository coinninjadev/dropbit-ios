//
//  ConfirmPaymentViewModel.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Contacts
import CNBitcoinKit

class BaseConfirmPaymentViewModel: DualAmountDisplayable {
  let address: String?
  let contact: ContactType?
  let walletTransactionType: WalletTransactionType
  var btcAmount: NSDecimalNumber
  let currencyPair: CurrencyPair
  let exchangeRates: ExchangeRates

  init(address: String?,
       contact: ContactType?,
       walletTransactionType: WalletTransactionType,
       btcAmount: NSDecimalNumber,
       currencyPair: CurrencyPair,
       exchangeRates: ExchangeRates) {
    self.address = address
    self.contact = contact
    self.walletTransactionType = walletTransactionType
    self.btcAmount = btcAmount
    self.currencyPair = currencyPair
    self.exchangeRates = exchangeRates
  }

  /// The btcAmount and fromAmount may or may not be the same
  var fromAmount: NSDecimalNumber {
    if currencyPair.primary == .BTC {
      return btcAmount
    } else {
      let converter = CurrencyConverter(rates: exchangeRates, fromAmount: btcAmount, currencyPair: currencyPair)
      let fiatAmount = converter.amount(forCurrency: currencyPair.fiat) ?? .zero
      return fiatAmount
    }
  }

  var memo: String? {
    return nil
  }

  var shouldShareMemo: Bool {
    return false
  }

  func update(with transactionData: CNBTransactionData) {
    self.btcAmount = NSDecimalNumber(integerAmount: Int(transactionData.amount), currency: .BTC)
  }

}

class ConfirmPaymentInviteViewModel: BaseConfirmPaymentViewModel {

  let sharedPayloadDTO: SharedPayloadDTO

  var addressPublicKeyState: AddressPublicKeyState {
    return .invite
  }

  override var memo: String? {
    return sharedPayloadDTO.memo
  }

  override var shouldShareMemo: Bool {
    return sharedPayloadDTO.shouldShare
  }

  init(address: String?,
       contact: ContactType?,
       walletTransactionType: WalletTransactionType,
       btcAmount: NSDecimalNumber,
       currencyPair: CurrencyPair,
       exchangeRates: ExchangeRates,
       sharedPayloadDTO: SharedPayloadDTO) {
    self.sharedPayloadDTO = sharedPayloadDTO
    super.init(address: address,
               contact: contact,
               walletTransactionType: walletTransactionType,
               btcAmount: btcAmount,
               currencyPair: currencyPair,
               exchangeRates: exchangeRates)
  }

}

class ConfirmPaymentViewModel: BaseConfirmPaymentViewModel {

  var outgoingTransactionData: OutgoingTransactionData

  var sharedPayloadDTO: SharedPayloadDTO? {
    return outgoingTransactionData.sharedPayloadDTO
  }

  override var memo: String? {
    return sharedPayloadDTO?.memo
  }

  override var shouldShareMemo: Bool {
    return sharedPayloadDTO?.shouldShare ?? false
  }

  init(address: String?,
       contact: ContactType?,
       walletTransactionType: WalletTransactionType,
       btcAmount: NSDecimalNumber,
       currencyPair: CurrencyPair,
       exchangeRates: ExchangeRates,
       outgoingTransactionData: OutgoingTransactionData) {
    self.outgoingTransactionData = outgoingTransactionData
    super.init(address: address,
               contact: contact,
               walletTransactionType: walletTransactionType,
               btcAmount: btcAmount,
               currencyPair: currencyPair,
               exchangeRates: exchangeRates)
  }

}

struct FeeRates {
  let high: Double
  let medium: Double
  let low: Double

  init?(fees: Fees) {
    guard let high = fees[.best], let medium = fees[.better], let low = fees[.good] else { return nil }
    self.high = high
    self.medium = medium
    self.low = low
  }

  func rate(forType type: TransactionFeeType) -> Double {
    switch type {
    case .fast:   return high
    case .slow:   return medium
    case .cheap:  return low
    }
  }
}

struct TransactionFeeConfig {
  let adjustableFeesEnabled: Bool
  let defaultFeeType: TransactionFeeType
  init(prefs: PreferencesBrokerType) {
    self.adjustableFeesEnabled = prefs.adjustableFeesIsEnabled
    self.defaultFeeType = prefs.preferredTransactionFeeType
  }
}

enum ConfirmTransactionFeeModel {
  case standard(CNBTransactionData)
  case required(CNBTransactionData)
  case adjustable(AdjustableTransactionFeeViewModel)

  var transactionData: CNBTransactionData {
    switch self {
    case .standard(let txData), .required(let txData):
      return txData
    case .adjustable(let vm):
      return vm.applicableTransactionData
    }
  }

  var feeAmount: Int {
    return Int(transactionData.feeAmount)
  }

}
