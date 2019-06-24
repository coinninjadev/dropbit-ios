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

protocol ConfirmPaymentViewModelType: SendPaymentDataProvider {
  var address: String? { get }
  var contact: ContactType? { get }
  var btcAmount: NSDecimalNumber? { get }
  var primaryCurrency: CurrencyCode { get }
  var rates: ExchangeRates { get }
  var sharedPayloadDTO: SharedPayloadDTO? { get }
  var feesViewModel: ConfirmAdjustableFeesViewModel { get }
}

struct ConfirmPaymentInviteViewModel: ConfirmPaymentViewModelType {
  var address: String?
  var contact: ContactType?
  var btcAmount: NSDecimalNumber?
  let primaryCurrency: CurrencyCode
  var feesViewModel: ConfirmAdjustableFeesViewModel
  let rates: ExchangeRates
  let sharedPayloadDTO: SharedPayloadDTO?

  var addressPublicKeyState: AddressPublicKeyState {
    return .invite
  }
}

struct ConfirmPaymentViewModel: ConfirmPaymentViewModelType {

  var address: String?
  var contact: ContactType?
  var btcAmount: NSDecimalNumber?
  var primaryCurrency: CurrencyCode
  var feesViewModel: ConfirmAdjustableFeesViewModel
  var outgoingTransactionData: OutgoingTransactionData
  var rates: ExchangeRates

  var transactionData: CNBTransactionData {
    return feesViewModel.applicableTransactionData
  }

  var sharedPayloadDTO: SharedPayloadDTO? {
    return outgoingTransactionData.sharedPayloadDTO
  }

  init(
    btcAmount: NSDecimalNumber,
    primaryCurrency: CurrencyCode,
    address: String?,
    contact: ContactType?,
    feeAdjustableTxData: FeeAdjustableTransactionData,
    outgoingTransactionData: OutgoingTransactionData,
    rates: ExchangeRates
    ) {
    self.btcAmount = btcAmount
    self.contact = contact
    self.primaryCurrency = primaryCurrency
    self.address = address
    self.feesViewModel = ConfirmAdjustableFeesViewModel(adjustableFeeData: feeAdjustableTxData)
    self.outgoingTransactionData = outgoingTransactionData
    self.rates = rates
  }

  init(
    btcAmount: NSDecimalNumber,
    primaryCurrency: CurrencyCode,
    address: String?,
    contact: ContactType?,
    outgoingTransactionData: OutgoingTransactionData,
    feeAdjustableTxData: FeeAdjustableTransactionData,
    rates: ExchangeRates
  ) {
    self.btcAmount = btcAmount
    self.contact = contact
    self.primaryCurrency = primaryCurrency
    self.address = address
    self.outgoingTransactionData = outgoingTransactionData
    self.feesViewModel = ConfirmAdjustableFeesViewModel(adjustableFeeData: feeAdjustableTxData)
    self.rates = rates
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
}

class FeeAdjustableTransactionData {

  let adjustableFeesEnabled: Bool
  let defaultFeeMode: TransactionFeeType
  var requiredFeeTxData: CNBTransactionData?
  let highFeeTxData: CNBTransactionData?
  let mediumFeeTxData: CNBTransactionData?
  let lowFeeTxData: CNBTransactionData // must not be nil

  init(isEnabled: Bool,
       defaultFeeMode: TransactionFeeType,
       highFeeTxData: CNBTransactionData?,
       mediumFeeTxData: CNBTransactionData?,
       lowFeeTxData: CNBTransactionData) {
    self.adjustableFeesEnabled = isEnabled
    self.highFeeTxData = highFeeTxData
    self.mediumFeeTxData = mediumFeeTxData
    self.lowFeeTxData = lowFeeTxData
    self.defaultFeeMode = defaultFeeMode
  }

}

class ConfirmAdjustableFeesViewModel: FeeAdjustableTransactionData {

  var selectedFeeMode: TransactionFeeType

  override init(isEnabled: Bool,
                defaultFeeMode: TransactionFeeType,
                highFeeTxData: CNBTransactionData?,
                mediumFeeTxData: CNBTransactionData?,
                lowFeeTxData: CNBTransactionData) {
    self.selectedFeeMode = defaultFeeMode
    super.init(isEnabled: isEnabled,
               defaultFeeMode: defaultFeeMode,
               highFeeTxData: highFeeTxData,
               mediumFeeTxData: mediumFeeTxData,
               lowFeeTxData: lowFeeTxData)
  }

  convenience init(adjustableFeeData data: FeeAdjustableTransactionData) {
    self.init(isEnabled: data.adjustableFeesEnabled,
              defaultFeeMode: data.defaultFeeMode,
              highFeeTxData: data.highFeeTxData,
              mediumFeeTxData: data.mediumFeeTxData,
              lowFeeTxData: data.lowFeeTxData)
  }

  private let sortedModes: [TransactionFeeType] = [.fast, .slow, .cheap]

  var selectedModeIndex: Int {
    return sortedModes.firstIndex(of: selectedFeeMode) ?? 0
  }

  var segmentModels: [AdjustableFeesSegmentViewModel] {
    return sortedModes.map { mode in
      return AdjustableFeesSegmentViewModel(title: self.title(for: mode),
                                            isEnabled: self.transactionData(for: mode) != nil,
                                            isSelected: mode == self.selectedFeeMode)
    }
  }

  var applicableFeeMode: TransactionFeeType {
    if adjustableFeesEnabled {
      return selectedFeeMode
    } else {
      return defaultFeeMode
    }
  }

  var applicableFee: Int {
    return fee(for: applicableFeeMode) ?? Int(lowFeeTxData.feeAmount)
  }

  var applicableTransactionData: CNBTransactionData {
    return transactionData(for: applicableFeeMode) ?? lowFeeTxData
  }

  func transactionData(for mode: TransactionFeeType) -> CNBTransactionData? {
    switch mode {
    case .fast:   return highFeeTxData
    case .slow:   return mediumFeeTxData
    case .cheap:  return lowFeeTxData
    }
  }

  func fee(for mode: TransactionFeeType) -> Int? {
    guard let txData = transactionData(for: mode) else { return nil }
    return Int(txData.feeAmount)
  }

  private func title(for mode: TransactionFeeType) -> String {
    switch mode {
    case .fast:   return "FAST"
    case .slow:   return "SLOW"
    case .cheap:  return "CHEAP"
    }
  }

  private var waitTimeDescription: String {
    switch selectedFeeMode {
    case .fast:   return "10 minutes"
    case .slow:   return "20-60 minutes"
    case .cheap:  return "24 hours+"
    }
  }

  var attributedWaitTimeDescription: NSAttributedString {
    let attrString = NSMutableAttributedString.light("Approximate wait time: ",
                                                     size: 11,
                                                     color: .darkBlueText)
    attrString.appendSemiBold(waitTimeDescription, size: 11)
    return attrString
  }

}

struct AdjustableFeesSegmentViewModel {
  let title: String
  let isEnabled: Bool
  let isSelected: Bool
}
