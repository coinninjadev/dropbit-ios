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
  var summaryStatusText: String? { get }
  var statusTextColor: UIColor { get }
  var counterpartyLabel: String? { get }
  var selectedCurrency: SelectedCurrency { get }
  var summaryAmountLabels: SummaryCellAmountLabels { get }
  var accentColor: UIColor { get } //amount and leading image background color
  var leadingImageConfig: SummaryCellLeadingImageConfig { get } // may be avatar or direction icon
  var memo: String? { get }
  var displayDate: String { get }
}

/// Defines the properties that need to be set during initialization of the view model.
/// The inherited `...Displayable` requirements should be calculated in this
/// protocol's extension or provided by a mock view model.
protocol TransactionSummaryCellViewModelType: TransactionSummaryCellDisplayable, CurrencyPairDisplayable {
  var walletTxType: WalletTransactionType { get }
  var direction: TransactionDirection { get }
  var isValidTransaction: Bool { get }
  var date: Date { get }
  var isLightningTransfer: Bool { get } //can be true for either onChain or lightning transactions
  var status: TransactionStatus { get }
  var counterpartyDescription: String? { get } //may be a name, phone number, raw destination, or nil if Twitter config exists
  var twitterConfig: TransactionCellTwitterConfig? { get }
  var amountDetails: TransactionAmountDetails { get }
  var memo: String? { get }
}

extension TransactionSummaryCellViewModelType {

  var leadingImageConfig: SummaryCellLeadingImageConfig {
    if let twitter = twitterConfig {
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
    case .in:   return .neonGreen
    case .out:  return .outgoingGray
    }
  }

  var summaryStatusText: String? {
    switch status {
    case .broadcasting: return "Broadcasting"
    default:            return nil
    }
  }

  var displayDate: String {
    return CKDateFormatter.displayFull.string(from: date)
  }

  var statusTextColor: UIColor {
    if isValidTransaction {
      switch status {
      case .broadcasting: return .warning
      default:            return .darkGrayText
      }
    } else {
      return .darkPeach
    }
  }

  var counterpartyLabel: String? {
    if let config = twitterConfig {
      return config.displayHandle
    } else {
      return counterpartyDescription
    }
  }

  var summaryAmountLabels: SummaryCellAmountLabels {
    let converter = CurrencyConverter(rates: amountDetails.exchangeRates,
                                      fromAmount: amountDetails.primaryBTCAmount,
                                      currencyPair: amountDetails.currencyPair)

    let btcAttributedString: NSAttributedString
    switch walletTxType {
    case .lightning:
      let sats = converter.btcAmount.asFractionalUnits(of: .BTC)
      btcAttributedString = attributedString(forSats: sats, size: 13)
    case .onChain:
      btcAttributedString = attributedString(for: converter.btcAmount, currency: .BTC)
    }

    let fiatAttributedString = attributedString(for: converter.fiatAmount, currency: converter.fiatCurrency)

    return SummaryCellAmountLabels(btcText: btcAttributedString, fiatText: fiatAttributedString.string)
  }

  var incomingImage: UIImage! {
    return UIImage(named: "summaryCellIncoming")!
  }

  var outgoingImage: UIImage! {
    return UIImage(named: "summaryCellOutgoing")!
  }

  var transferImage: UIImage! {
    return UIImage(named: "summaryCellTransfer")!
  }

  var lightningImage: UIImage! {
    return UIImage(named: "summaryCellLightning")!
  }

  var invalidImage: UIImage! {
    return UIImage(named: "summaryCellInvalid")!
  }

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
}

struct TransactionAmountDetails {
  let currencyPair: CurrencyPair
  let exchangeRates: ExchangeRates
  let primaryBTCAmount: NSDecimalNumber
  let fiatWhenCreated: NSDecimalNumber?
  let fiatWhenTransacted: NSDecimalNumber?
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

struct TransactionCellTwitterConfig {
  let avatar: UIImage
  let displayHandle: String
}

struct SummaryCellAmountLabels {
  let btcText: NSAttributedString //may be lightning or on-chain amount
  let fiatText: String
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

  var avatarViewIsHidden: Bool { return avatarConfig == nil }
  var directionViewIsHidden: Bool { return directionConfig == nil }
}

/// Only one of the secondary strings should be set
struct DetailCellAmountLabels {
  let primaryText: String
  let secondaryText: String?
  let secondaryAttributedText: NSAttributedString?
  let historicalPriceAttributedText: NSAttributedString?
}
