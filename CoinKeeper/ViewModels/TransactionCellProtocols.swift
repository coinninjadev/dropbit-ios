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
  var summaryTransactionDescription: String { get }
  var selectedCurrency: SelectedCurrency { get }
  var summaryAmountLabels: SummaryCellAmountLabels { get }
  var accentColor: UIColor { get } //amount and leading image background color
  var leadingImageConfig: SummaryCellLeadingImageConfig { get } // may be avatar or direction icon
  var memo: String? { get }
  var isLightningTransfer: Bool { get } //can be true for either onChain or lightning transactions
  var cellBackgroundColor: UIColor { get }
}

extension TransactionSummaryCellDisplayable {

  var cellBackgroundColor: UIColor { return .white }
  var shouldHideAvatarView: Bool { return leadingImageConfig.avatarConfig == nil }
  var shouldHideDirectionView: Bool { return leadingImageConfig.directionConfig == nil }
  var shouldHideMemoLabel: Bool {
    let memoIsEmpty = (memo ?? "").isEmpty
    return isLightningTransfer || memoIsEmpty
  }

}

/// Defines the properties that need to be set during initialization of the view model.
/// The inherited `...Displayable` requirements should be calculated in this
/// protocol's extension or provided by a mock view model.
protocol TransactionSummaryCellViewModelType: TransactionSummaryCellDisplayable {
  var direction: TransactionDirection { get }
  var status: TransactionStatus { get }
  var counterpartyConfig: TransactionCellCounterpartyConfig? { get } //may be nil for transfers

  /// This address may belong to the wallet or the counterparty depending on the direction
  var receiverAddress: String? { get }
  var lightningInvoice: String? { get }
  var amountDetails: TransactionAmountDetails { get }
  var memo: String? { get }
  var isLightningUpgrade: Bool { get }
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
    let directionConfig = TransactionCellDirectionConfig(bgColor: accentColor, image: directionIcon)
    return SummaryCellLeadingImageConfig(twitterConfig: counterpartyConfig?.twitterConfig,
                                         directionConfig: directionConfig)
  }

  /// Transaction type icon, not an avatar
  var directionIcon: UIImage {
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
    guard !isLightningTransfer else { return false }
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

  var summaryTransactionDescription: String {
    if let transferType = lightningTransferType {
      switch transferType {
      case .withdraw:   return lightningWithdrawText
      case .deposit:    return lightningDepositText
      }
    } else if let counterparty = counterpartyDescription {
      return counterparty
    } else if let invoiceText = lightningInvoiceDescription {
      return invoiceText
    } else if isLightningUpgrade {
      return "Lightning Upgrade"
    } else if let address = receiverAddress {
      return address
    } else {
      return "(unknown)"
    }
  }

  var lightningTransferType: LightningTransferType? {
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

  var counterpartyDescription: String? {
    guard let config = counterpartyConfig else { return nil }
    if let twitter = config.twitterConfig {
      return twitter.displayHandle
    } else if let name = config.displayName {
      return name
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

  var incomingImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellIncoming") }
  var outgoingImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellOutgoing") }
  var transferImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellTransfer") }
  var lightningImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellLightning") }
  var invalidImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellInvalid") }

}

// MARK: - Detail Cell

/// Provides all variable values directly necessary to configure the TransactionHistoryDetailCell UI.
/// Fixed values (colors, font sizes, etc.) are provided by the cell itself.
protocol TransactionDetailCellDisplayable: TransactionSummaryCellDisplayable {
  var directionConfig: TransactionCellDirectionConfig { get }
  var detailStatusText: String { get }
  var detailStatusColor: UIColor { get }
  var twitterConfig: TransactionCellTwitterConfig? { get }
  var counterpartyText: String? { get }
  var memoConfig: DetailCellMemoConfig? { get }
  var canAddMemo: Bool { get }
  var displayDate: String { get }
  var messageText: String? { get }
  var progressConfig: ProgressBarConfig? { get }

//  var bitcoinAddress: String? { get }
//  var actionButtonConfig: DetailCellActionButtonConfig? { get }
}

extension TransactionDetailCellDisplayable {

  var shouldHideCounterpartyLabel: Bool { return counterpartyText == nil }
  var shouldHideMemoView: Bool { return shouldHideMemoLabel }
  var shouldHideAddMemoButton: Bool { return !canAddMemo }
  var shouldHideMessageLabel: Bool { return messageText == nil }
  var shouldHideProgressView: Bool { return progressConfig == nil }

//  var transactionStatusDescription: String {
//    guard !isTemporaryTransaction else { return "Broadcasting" }
//    let count = confirmations
//    switch count {
//    case 0:    return "Pending"
//    default:  return "Complete"
//    }
//  }

//  var statusDescription: String {
//    if broadcastFailed {
//      return "Failed to Broadcast"
//    } else {
//      return invitationStatusDescription ?? transactionStatusDescription
//    }
//  }

}

protocol TransactionInvalidDetailCellDisplayable: TransactionDetailCellDisplayable {
  var status: TransactionStatus { get }
}

extension TransactionInvalidDetailCellDisplayable {

  var statusTextColor: UIColor {
    return .warningText
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
  var memoIsShared: Bool { get }
  var invitationStatus: InvitationStatus? { get }
  var onChainConfirmations: Int? { get }

//  var action: TransactionDetailAction? { get }
}

extension TransactionDetailCellViewModelType {

  var directionConfig: TransactionCellDirectionConfig {
    return TransactionCellDirectionConfig(bgColor: accentColor, image: directionIcon)
  }

  var detailStatusText: String {
    switch status {
    case .pending:      return pendingStatusText
    case .completed:    return completedStatusText
    case .broadcasting: return string(for: .broadcasting)
    case .canceled:     return string(for: .dropBitCanceled)
    case .expired:      return string(for: .transactionExpired)
    case .failed:       return string(for: .broadcastFailed)
    }
  }

  private var pendingStatusText: String {
    if isDropBit {
      switch direction {
      case .out:
        switch walletTxType {
        case .onChain:    return string(for: .dropBitSent)
        case .lightning:  return string(for: .dropBitSentInvitePending)
        }
      case .in:
        return string(for: .pending)
      }
    } else {
      return string(for: .pending)
    }
  }

  private var completedStatusText: String {
    if let transferType = lightningTransferType {
      switch transferType {
      case .deposit:    return string(for: .loadLightning)
      case .withdraw:   return string(for: .withdrawFromLightning)
      }
    } else {
      switch walletTxType {
      case .onChain:    return string(for: .complete)
      case .lightning:  return string(for: .invoicePaid)
      }
    }
  }

  var detailStatusColor: UIColor {
    return isValidTransaction ? .darkGrayText : .warningText
  }

  var progressConfig: ProgressBarConfig? {
    if walletTxType == .lightning { return nil }
    if statusShouldHideProgressConfig { return nil }

    if isInvitation {
      return ProgressBarConfig(titles: ["", "", "", "", ""],
                               stepTitles: ["1", "2", "3", "4", "✓"],
                               width: 250,
                               selectedTab: invitationProgressStep)
    }
    return ProgressBarConfig(titles: ["", "", ""],
                             stepTitles: ["1", "2", "✓"],
                             width: 130,
                             selectedTab: genericTransactionProgressStep)
  }

  private var isConfirmed: Bool {
    guard let confirmations = onChainConfirmations else { return false }
    return confirmations >= 1
  }

  private var invitationProgressStep: Int {
    guard let invitationStatus = invitationStatus else { return 0 }
    if isConfirmed {
      return 5
    } else {
      switch invitationStatus {
      case .completed:
        if status == .broadcasting {
          return 3
        } else {
          return 4
        }
      case .addressSent:
        return 2
      default:
        return 1
      }
    }
  }

  private var genericTransactionProgressStep: Int {
    if isConfirmed {
      return 3
    } else if status == .broadcasting {
      return 1
    } else {
      return 2
    }
  }

  private var statusShouldHideProgressConfig: Bool {
    switch status {
    case .completed, .expired, .canceled, .failed:
      return true
    default:
      return false
    }
  }

  /// May be an invitation or a transaction between registered users
  private var isDropBit: Bool {
    return counterpartyConfig != nil
  }

  private var isInvitation: Bool {
    return invitationStatus != nil
  }

  var twitterConfig: TransactionCellTwitterConfig? {
    return self.counterpartyConfig?.twitterConfig
  }

  var counterpartyText: String? {
    return counterpartyDescription
  }

  var detailAmountLabels: DetailCellAmountLabels {
    return DetailCellAmountLabels(primaryText: "",
                                  secondaryText: nil,
                                  secondaryAttributedText: nil,
                                  historicalPriceAttributedText: nil)

//    let converter = CurrencyConverter(rates: amountDetails.exchangeRates,
//                                      fromAmount: amountDetails.btcAmount,
//                                      currencyPair: amountDetails.currencyPair)

//    var btcAttributedString: NSAttributedString?
//    if walletTxType == .onChain {
//      btcAttributedString = BitcoinFormatter(symbolType: .attributed).attributedString(from: converter.btcAmount)
//    }
//
//    let signedFiatAmount = self.signedAmount(for: converter.fiatAmount)
//    let satsText = SatsFormatter().string(fromDecimal: converter.btcAmount) ?? ""
//    let fiatText = FiatFormatter(currency: converter.fiatCurrency,
//                                 withSymbol: true,
//                                 showNegativeSymbol: true).string(fromDecimal: signedFiatAmount) ?? ""
//
//    let pillText: String = isValidTransaction ? fiatText : status.rawValue
//
//    return SummaryCellAmountLabels(btcAttributedText: btcAttributedString,
//                                   satsText: satsText,
//                                   pillText: pillText,
//                                   pillIsAmount: isValidTransaction)
  }

  var memoConfig: DetailCellMemoConfig? {
    guard let memoText = memo else { return nil }
    let isSent = self.status == .completed
    let isIncoming = direction == .in
    return DetailCellMemoConfig(memo: memoText, isShared: memoIsShared, isSent: isSent,
                                isIncoming: isIncoming, recipientName: counterpartyText)
  }

  var canAddMemo: Bool {
    if isLightningTransfer { return false }
    return memoConfig == nil
  }

  /**
   If not nil, this string will appear in the gray rounded container instead of the breakdown amounts.
   */
  var messageText: String? {
    if let status = invitationStatus, status == .addressSent, let counterpartyDesc = counterpartyDescription {
      let messageWithLineBreaks = """
      Your Bitcoin address has been sent to
      \(counterpartyDesc).
      Once approved, this transaction will be completed.
      """

      return sizeSensitiveMessage(from: messageWithLineBreaks)

    } else {
      return nil
    }
  }

  /// Strips static linebreaks from the string on small devices
  private func sizeSensitiveMessage(from message: String) -> String {
    let shouldUseStaticLineBreaks = (UIScreen.main.relativeSize == .tall)
    if shouldUseStaticLineBreaks {
      return message
    } else {
      return message.removingMultilineLineBreaks()
    }
  }

  var displayDate: String {
    return CKDateFormatter.displayFull.string(from: date)
  }

//  var actionButtonConfig: DetailCellActionButtonConfig? {
//    guard let a = action else { return nil }
//    switch a {
//    case .cancelInvitation:
//      return DetailCellActionButtonConfig(title: "CANCEL", backgroundColor: .warning)
//    case .seeDetails:
//      let buttonColor: UIColor
//      switch walletTxType {
//      case .lightning:  buttonColor = .lightningBlue
//      case .onChain:    buttonColor = .bitcoinOrange
//      }
//      return DetailCellActionButtonConfig(title: "DETAILS", backgroundColor: buttonColor)
//    }
//  }

  func string(for stringId: DetailCellString) -> String {
    return stringId.rawValue
  }

}

enum DetailCellString: String {
  case broadcasting = "Broadcasting"
  case broadcastFailed = "Failed to Broadcast"
  case pending = "Pending"
  case complete = "Complete"
  case dropBitSent = "DropBit Sent"
  case dropBitSentInvitePending = "DropBit Sent - Invite Pending"
  case dropBitCanceled = "DropBit Canceled"
  case transactionExpired = "Transaction Expired"
  case invoicePaid = "Invoice Paid"
  case loadLightning = "Load Lightning"
  case withdrawFromLightning = "Withdraw from Lightning"
}
