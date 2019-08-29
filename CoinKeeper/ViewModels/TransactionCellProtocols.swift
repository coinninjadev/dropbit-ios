//
//  TransactionCellProtocols.swift
//  DropBit
//
//  Created by Ben Winters on 7/31/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Summary Cell

/// Provides all variable values directly necessary to configure the TransactionHistorySummaryCell UI.
/// Fixed values (colors, font sizes, etc.) are provided by the cell itself.
protocol TransactionSummaryCellDisplayable {
  var walletTxType: WalletTransactionType { get }
  var counterpartyText: String { get }
  var selectedCurrency: SelectedCurrency { get }
  var summaryAmountLabels: SummaryCellAmountLabels { get }
  var accentColor: UIColor { get } //amount and leading image background color
  var leadingImageConfig: SummaryCellLeadingImageConfig { get } // may be avatar or direction icon
  var memo: String? { get }
  var cellBackgroundColor: UIColor { get }
}

extension TransactionSummaryCellDisplayable {

  var cellBackgroundColor: UIColor { return .white }
  var avatarViewIsHidden: Bool { return leadingImageConfig.avatarConfig == nil }
  var directionViewIsHidden: Bool { return leadingImageConfig.directionConfig == nil }
  var memoLabelIsHidden: Bool { return memo == nil || memo == "" }

}

/// Defines the properties that need to be set during initialization of the view model.
/// The inherited `...Displayable` requirements should be calculated in this
/// protocol's extension or provided by a mock view model.
protocol TransactionSummaryCellViewModelType: TransactionSummaryCellDisplayable {
  var direction: TransactionDirection { get }
  var isLightningTransfer: Bool { get } //can be true for either onChain or lightning transactions
  var status: TransactionStatus { get }
  var counterpartyConfig: TransactionCellCounterpartyConfig? { get } //may be nil for transfers

  /// This address may belong to the wallet or the counterparty depending on the direction
  var receiverAddress: String? { get }
  var lightningInvoice: String? { get }
  var amountDetails: TransactionAmountDetails { get }
  var memo: String? { get }
}

extension TransactionSummaryCellViewModelType {

  var isValidTransaction: Bool {
    switch status {
    case .canceled,
         .expired,
         .failed:   return false
    default:        return true
    }
  }

  var leadingImageConfig: SummaryCellLeadingImageConfig {
    if let twitter = counterpartyConfig?.twitterConfig {
      return SummaryCellLeadingImageConfig(twitterConfig: twitter)

    } else {
      return SummaryCellLeadingImageConfig(bgColor: accentColor, leadingIcon: leadingIcon)
    }
  }

  /// Transaction type icon, not an avatar
  private var leadingIcon: UIImage {
    guard isValidTransaction else { return invalidImage }

    if isLightningTransfer {
      return transferImage
    } else {
      switch walletTxType {
      case .lightning:  return isPendingInvoice ? lightningImage : directionImage
      case .onChain:    return directionImage
      }
    }
  }

  var accentColor: UIColor {
    guard isValidTransaction else { return .invalid }

    if isPendingInvoice {
      return .lightningBlue
    } else {
      return directionColor
    }
  }

  private var isPendingInvoice: Bool {
    return walletTxType == .lightning && status == .pending
  }

  private var directionImage: UIImage {
    switch direction {
    case .in:   return incomingImage
    case .out:  return outgoingImage
    }
  }

  private var directionColor: UIColor {
    switch direction {
    case .in:   return .incomingGreen
    case .out:  return .outgoingGray
    }
  }

  var counterpartyText: String {
    if let transferType = lightningTransferType {
      switch transferType {
      case .withdraw:   return lightningWithdrawText
      case .deposit:    return lightningDepositText
      }
    } else if let counterparty = counterpartyDescription {
      return counterparty
    } else if let invoiceText = lightningInvoiceDescription {
      return invoiceText
    } else if let address = receiverAddress {
      return address
    } else {
      return "(unknown)"
    }
  }

  private var lightningTransferType: LightningTransferType? {
    guard isLightningTransfer else { return nil }
    switch walletTxType {
    case .onChain:
      return (direction == .in) ? .withdraw : .deposit
    case .lightning:
      return (direction == .in) ? .deposit : .withdraw
    }
  }

  private var lightningInvoiceDescription: String? {
    guard (lightningInvoice ?? "").isNotEmpty else { return nil }
    switch status {
    case .completed:  return lightningPaidInvoiceText
    default:          return lightningUnpaidInvoiceText
    }
  }

  private var counterpartyDescription: String? {
    guard let config = counterpartyConfig else { return nil }
    if let name = config.displayName {
      return name
    } else if let twitter = config.twitterConfig {
      return twitter.displayHandle
    } else if let phoneNumber = config.displayPhoneNumber {
      return phoneNumber
    } else {
      return nil
    }
  }

  var summaryAmountLabels: SummaryCellAmountLabels {
    let converter = CurrencyConverter(rates: amountDetails.exchangeRates,
                                      fromAmount: amountDetails.btcAmount,
                                      currencyPair: amountDetails.currencyPair)

    var btcAttributedString: NSAttributedString?
    if walletTxType == .onChain {
      btcAttributedString = BitcoinFormatter(symbolType: .attributed).attributedString(from: converter.btcAmount)
    }

    let signedFiatAmount = self.signedAmount(for: converter.fiatAmount)
    let satsText = SatsFormatter().string(fromDecimal: converter.btcAmount) ?? ""
    let fiatText = FiatFormatter(currency: converter.fiatCurrency,
                                 withSymbol: true,
                                 showNegativeSymbol: true).string(fromDecimal: signedFiatAmount) ?? ""

    let pillText: String = isValidTransaction ? fiatText : status.rawValue

    return SummaryCellAmountLabels(btcAttributedText: btcAttributedString,
                                   satsText: satsText,
                                   pillText: pillText,
                                   pillIsAmount: isValidTransaction)
  }

  private func signedAmount(for amount: NSDecimalNumber) -> NSDecimalNumber {
    guard !amount.isNegativeNumber else { return amount }
    switch direction {
    case .in:   return amount
    case .out:  return amount.multiplying(by: NSDecimalNumber(value: -1))
    }
  }

  var lightningPaidInvoiceText: String { return "Invoice Paid" }
  var lightningUnpaidInvoiceText: String { return "Lightning Invoice" }
  var lightningWithdrawText: String { return "Lightning Withdraw" }
  var lightningDepositText: String { return "Load Lightning" }

  var incomingImage: UIImage! { return UIImage(named: "summaryCellIncoming")! }
  var outgoingImage: UIImage! { return UIImage(named: "summaryCellOutgoing")! }
  var transferImage: UIImage! { return UIImage(named: "summaryCellTransfer")! }
  var lightningImage: UIImage! { return UIImage(named: "summaryCellLightning")! }
  var invalidImage: UIImage! { return UIImage(named: "summaryCellInvalid")! }

}

// MARK: - Detail Cell

/// Provides all variable values directly necessary to configure the TransactionHistoryDetailCell UI.
/// Fixed values (colors, font sizes, etc.) are provided by the cell itself.
protocol TransactionDetailCellDisplayable: TransactionSummaryCellDisplayable {
  var detailStatusText: String? { get }
  var progressConfig: ProgressBarConfig? { get }
  var bitcoinAddress: String? { get }
  var memoConfig: DetailCellMemoConfig? { get }
  var canAddMemo: Bool { get }
  var actionButtonConfig: DetailCellActionButtonConfig? { get }
  var displayDate: String { get }
}

extension TransactionDetailCellDisplayable {

  var statusTextColor: UIColor {
    return .lightGrayText
  }
}

protocol TransactionInvalidDetailCellDisplayable: TransactionDetailCellDisplayable {
  var status: TransactionStatus { get }
}

extension TransactionInvalidDetailCellDisplayable {

  var statusTextColor: UIColor {
    return .warning
  }

  var directionImage: UIImage? {
    return UIImage(named: "invalidDetailIcon")
  }

  var warningMessage: String? {
    switch status {
    case .expired:
      return """
      For security reasons we can only allow
      48 hours to accept a transaction.
      This transaction has expired.
      """
    default:
      return nil
    }
  }
}

/// Defines the properties that need to be set during initialization of the view model.
/// The inherited `...Displayable` requirements should be calculated in this
/// protocol's extension or provided by a mock view model.
protocol TransactionDetailCellViewModelType: TransactionSummaryCellViewModelType, TransactionDetailCellDisplayable {
  var date: Date { get }
  var action: TransactionDetailAction? { get }
}

extension TransactionDetailCellViewModelType {

  var statusTextColor: UIColor { return .lightGrayText }

  var canAddMemo: Bool {
    if isLightningTransfer { return false }
    return memoConfig == nil
  }

  var detailStatusText: String? {
    return status.rawValue
  }

  var amountLabels: DetailCellAmountLabels {
    return DetailCellAmountLabels(primaryText: "",
                                  secondaryText: nil,
                                  secondaryAttributedText: nil,
                                  historicalPriceAttributedText: nil)
  }

  var displayDate: String {
    return CKDateFormatter.displayFull.string(from: date)
  }

  var actionButtonConfig: DetailCellActionButtonConfig? {
    guard let a = action else { return nil }
    switch a {
    case .cancelInvitation:
      return DetailCellActionButtonConfig(title: "CANCEL", backgroundColor: .warning)
    case .removeInvoice:
      return DetailCellActionButtonConfig(title: "REMOVE FROM TRANSACTION LIST", backgroundColor: .warning)
    case .seeDetails:
      let buttonColor: UIColor
      switch walletTxType {
      case .lightning:  buttonColor = .lightningBlue
      case .onChain:    buttonColor = .bitcoinOrange
      }
      return DetailCellActionButtonConfig(title: "DETAILS", backgroundColor: buttonColor)
    }
  }

}

enum TransactionDirection: String {
  case `in`, out
}

enum TransactionStatus: String {
  case pending
  case broadcasting
  case completed
  case canceled
  case expired
  case failed
}

private enum LightningTransferType {
  case deposit, withdraw
}

struct TransactionAmountDetails {
  let btcAmount: NSDecimalNumber
  let currencyPair: CurrencyPair
  let exchangeRates: ExchangeRates
  let fiatWhenCreated: NSDecimalNumber?
  let fiatWhenTransacted: NSDecimalNumber?

  init(btcAmount: NSDecimalNumber,
       fiatCurrency: CurrencyCode,
       exchangeRates: ExchangeRates,
       fiatWhenCreated: NSDecimalNumber? = nil,
       fiatWhenTransacted: NSDecimalNumber? = nil) {
    self.currencyPair = CurrencyPair(primary: .BTC, fiat: fiatCurrency)
    self.exchangeRates = exchangeRates
    self.btcAmount = btcAmount
    self.fiatWhenCreated = fiatWhenCreated
    self.fiatWhenTransacted = fiatWhenTransacted
  }

  init(fiatAmount: NSDecimalNumber,
       fiatCurrency: CurrencyCode,
       exchangeRates: ExchangeRates,
       fiatWhenCreated: NSDecimalNumber? = nil,
       fiatWhenTransacted: NSDecimalNumber? = nil) {
    let fiatCurrencyPair = CurrencyPair(primary: fiatCurrency, fiat: fiatCurrency)
    let converter = CurrencyConverter(rates: exchangeRates,
                                      fromAmount: fiatAmount,
                                      currencyPair: fiatCurrencyPair)
    self.init(btcAmount: converter.btcAmount,
              fiatCurrency: fiatCurrency,
              exchangeRates: exchangeRates,
              fiatWhenCreated: fiatWhenCreated,
              fiatWhenTransacted: fiatWhenTransacted)
  }
}

struct ProgressBarConfig {
  let titles: [String]
  let stepTitles: [String]
  let width: CGFloat
  let selectedTabIndex: Int
}

struct LightningInvoiceDisplayDetails {
  let invoiceStatus: InvoiceStatus
  let qrCode: UIImage
  let request: String
  let memo: String?

  enum InvoiceStatus {
    case pending(Int) //associated value is hours remaining
    case expired
    case paid
  }

  var canRemoveFromTransactionList: Bool {
    if case .expired = invoiceStatus {
      return true
    } else {
      return false
    }
  }
}

struct DetailCellActionButtonConfig {
  let title: String
  let backgroundColor: UIColor
}

struct DetailCellMemoConfig {
  let memo: String
  let isShared: Bool
  let sharingDescription: String?
  let sharingIcon: UIImage?
}

struct TransactionCellCounterpartyConfig {
  let displayName: String?
  let displayPhoneNumber: String?
  let twitterConfig: TransactionCellTwitterConfig?

  init(displayName: String? = nil, displayPhoneNumber: String? = nil, twitterConfig: TransactionCellTwitterConfig? = nil) {
    guard (displayName != nil) || (displayPhoneNumber != nil) || (twitterConfig != nil) else {
      let message = "At least one parameter should be non-nil when initializing the counterparty config"
      log.error(message)
      fatalError(message)
    }
    self.displayName = displayName
    self.displayPhoneNumber = displayPhoneNumber
    self.twitterConfig = twitterConfig
  }

}

struct TransactionCellTwitterConfig {
  let avatar: UIImage
  let displayHandle: String
}

struct SummaryCellAmountLabels {
  let btcAttributedText: NSAttributedString? //may be lightning or on-chain amount
  let satsText: String //this is always available, btcAttributedText takes precedence if set
  let pillText: String //may be amount or status description
  let pillIsAmount: Bool
}

struct SummaryCellDirectionConfig {
  let bgColor: UIColor
  let image: UIImage
}

struct SummaryCellAvatarConfig {
  let image: UIImage
}

struct SummaryCellLeadingImageConfig {
  let avatarConfig: SummaryCellAvatarConfig?
  let directionConfig: SummaryCellDirectionConfig?

  init(avatarConfig: SummaryCellAvatarConfig?,
       directionConfig: SummaryCellDirectionConfig?) {
    self.avatarConfig = avatarConfig
    self.directionConfig = directionConfig
  }

  init(twitterConfig: TransactionCellTwitterConfig) {
    self.avatarConfig = SummaryCellAvatarConfig(image: twitterConfig.avatar)
    self.directionConfig = nil
  }

  init(bgColor: UIColor, leadingIcon: UIImage) {
    self.avatarConfig = nil
    self.directionConfig = SummaryCellDirectionConfig(bgColor: bgColor,
                                                      image: leadingIcon)
  }

}

/// Only one of the secondary strings should be set
struct DetailCellAmountLabels {
  let primaryText: String
  let secondaryText: String?
  let secondaryAttributedText: NSAttributedString?
  let historicalPriceAttributedText: NSAttributedString?
}
