//
//  ConfirmPaymentViewModel.swift
//  DropBit
//
//  Created by Mitchell on 4/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Contacts
import Cnlib

class BaseConfirmPaymentViewModel: DualAmountDisplayable {

  let paymentTarget: String? //address or encoded invoice
  let contact: ContactType?
  let walletTransactionType: WalletTransactionType
  var btcAmount: NSDecimalNumber
  let currencyPair: CurrencyPair
  let exchangeRates: ExchangeRates

  init(paymentTarget: String?,
       contact: ContactType?,
       walletTransactionType: WalletTransactionType,
       btcAmount: NSDecimalNumber,
       currencyPair: CurrencyPair,
       exchangeRates: ExchangeRates) {
    self.paymentTarget = paymentTarget
    self.contact = contact
    self.walletTransactionType = walletTransactionType
    self.btcAmount = btcAmount
    self.currencyPair = currencyPair
    self.exchangeRates = exchangeRates
  }

  func selectedCurrency() -> SelectedCurrency {
    return currencyPair.primary.isFiat ? .fiat : .BTC
  }

  var primaryAmountFontSize: CGFloat { 35 }

  var bitcoinFormatter: BitcoinFormatter {
    if selectedCurrency() == .BTC {
      let font: UIFont = .bitcoinSymbolFont(primaryAmountFontSize)
      return BitcoinFormatter(symbolType: .string, symbolFont: font)
    } else {
      return BitcoinFormatter(symbolType: .image)
    }
  }

  var fromAmount: NSDecimalNumber { btcAmount }

  ///Custom implementation, ignoring currencyPair which is used for display order
  var currencyConverter: CurrencyConverter {
    return CurrencyConverter(fromBtcTo: currencyPair.fiat, fromAmount: fromAmount, rates: exchangeRates)
  }

  var memo: String? {
    return nil
  }

  var shouldShareMemo: Bool {
    return false
  }

  func update(with transactionData: CNBCnlibTransactionData?) {
    guard let txData = transactionData else { return }
    self.btcAmount = NSDecimalNumber(integerAmount: Int(txData.amount), currency: .BTC)
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

  init(contact: ContactType?,
       walletTransactionType: WalletTransactionType,
       btcAmount: NSDecimalNumber,
       currencyPair: CurrencyPair,
       exchangeRates: ExchangeRates,
       sharedPayloadDTO: SharedPayloadDTO) {
    self.sharedPayloadDTO = sharedPayloadDTO
    super.init(paymentTarget: nil,
               contact: contact,
               walletTransactionType: walletTransactionType,
               btcAmount: btcAmount,
               currencyPair: currencyPair,
               exchangeRates: exchangeRates)
  }

}

class ConfirmOnChainPaymentViewModel: BaseConfirmPaymentViewModel {

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

  init(address: String,
       contact: ContactType?,
       btcAmount: NSDecimalNumber,
       currencyPair: CurrencyPair,
       exchangeRates: ExchangeRates,
       outgoingTransactionData: OutgoingTransactionData) {
    self.outgoingTransactionData = outgoingTransactionData
    super.init(paymentTarget: address,
               contact: contact,
               walletTransactionType: .onChain,
               btcAmount: btcAmount,
               currencyPair: currencyPair,
               exchangeRates: exchangeRates)
  }

  convenience init(inputs: SendOnChainPaymentInputs) {
    self.init(address: inputs.address,
              contact: inputs.contact,
              btcAmount: inputs.btcAmount,
              currencyPair: inputs.currencyPair,
              exchangeRates: inputs.exchangeRates,
              outgoingTransactionData: inputs.outgoingTxData)
  }

}

class ConfirmLightningPaymentViewModel: BaseConfirmPaymentViewModel {

  let invoice: String
  let sharedPayloadDTO: SharedPayloadDTO?

  override var memo: String? {
    return sharedPayloadDTO?.memo
  }

  override var shouldShareMemo: Bool {
    return sharedPayloadDTO?.shouldShare ?? false
  }

  init(invoice: String,
       contact: ContactType?,
       btcAmount: NSDecimalNumber,
       sharedPayload: SharedPayloadDTO?,
       currencyPair: CurrencyPair,
       exchangeRates: ExchangeRates) {
    self.invoice = invoice
    self.sharedPayloadDTO = sharedPayload
    super.init(paymentTarget: invoice,
               contact: contact,
               walletTransactionType: .lightning,
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
  case standard(CNBCnlibTransactionData)
  case required(CNBCnlibTransactionData)
  case adjustable(AdjustableTransactionFeeViewModel)
  case lightning

  var transactionData: CNBCnlibTransactionData? {
    switch self {
    case .standard(let txData), .required(let txData):
      return txData
    case .adjustable(let vm):
      return vm.applicableTransactionData
    case .lightning:
      return nil
    }
  }

  var networkFeeAmount: Int {
    guard let txData = transactionData else { return 0 }
    return Int(txData.feeAmount)
  }

}
