//
//  TransactionDetailCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 4/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

/**
 Translates a Transaction object and it's relationships into a cell-displayable object.
 */

class OldTransactionDetailCellViewModel: OldTransactionSummaryCellViewModel {
  var isCancellable: Bool
  var memoWasShared: Bool
  var networkFee: NSDecimalNumber?

  override init(
    transaction: CKMTransaction,
    rates: ExchangeRates,
    primaryCurrency: CurrencyCode,
    deviceCountryCode: Int?
    ) {
    let fee = transaction.networkFee
    self.isCancellable = transaction.isCancellable
    self.networkFee = NSDecimalNumber(integerAmount: fee, currency: .BTC)
    self.memoWasShared = transaction.sharedPayload?.sharingDesired ?? false

    super.init(
      transaction: transaction,
      rates: rates,
      primaryCurrency: primaryCurrency,
      deviceCountryCode: deviceCountryCode
    )
  }
}

private struct TextAttributes {
  var size: CGFloat
  var color: UIColor
}

extension OldTransactionDetailCellViewModel {

  var isShareable: Bool {
    return transaction?.txidIsActualTxid ?? false
  }

  var imageForTransactionDirection: UIImage? {
    if transactionIsInvalidated {
      return UIImage(named: "invalidated40")
    } else {
      return isIncoming ? UIImage(named: "incoming40") : UIImage(named: "outgoing40")
    }
  }

  var bottomButtonAction: TransactionDetailAction? {
    guard !broadcastFailed else { return nil }

    if isCancellable {
      return .cancelInvitation
    } else if isShareable {
      return .seeDetails
    } else {
      return nil
    }
  }

  var transactionStatusDescription: String {
    guard !isTemporaryTransaction else { return "Broadcasting" }
    let count = confirmations
    switch count {
    case 0:    return "Pending"
    default:  return "Complete"
    }
  }

  var statusDescription: String {
    if broadcastFailed {
      return "Failed to Broadcast"
    } else {
      return invitationStatusDescription ?? transactionStatusDescription
    }
  }

  var descriptionColor: UIColor {
    guard !transactionIsInvalidated else { return .darkPeach }
    if isConfirmed {
      return .darkGrayText
    } else {
      return .warningText
    }
  }

  // MARK: Currency Converters
  /**
   Converters with rates for sent, received, and current dates.
   These refer to the sentAmountAtCurrentConverter for the fromCurrency, toCurrency, and current rates (if relevant).
   */

  /// The amounts from this converter are valid for both the sender and receiver
  var receivedAmountAtSentConverter: CurrencyConverter? {
    guard let amount = btcReceived, let rate = transaction?.dayAveragePrice?.doubleValue else { return nil }
    return newConverter(withRate: rate, currency: .USD, btcAmount: amount)
  }

  var feeAmountAtCurrentConverter: CurrencyConverter? {
    guard let amount = networkFee, let rate = currentRate(for: .USD) else { return nil }
    return newConverter(withRate: rate, currency: .USD, btcAmount: amount)
  }

  // MARK: - Labels
  ///Used for primaryAmountLabel and secondaryAmountLabel
  private var receivedAmountsConverter: CurrencyConverter {
    //fall back to sent amount if received amount / fees are not yet known
    return receivedAmountAtCurrentConverter ?? sentAmountAtCurrentConverter
  }

  var primaryAmountLabel: String? {
    return stringWithSymbol(converter: receivedAmountsConverter, currency: primaryCurrency)
  }

  var secondaryAmountLabel: NSAttributedString? {
    let converter = receivedAmountsConverter
    let currency = converter.otherCurrency(forCurrency: primaryCurrency)
    guard let amount = converter.amount(forCurrency: currency) else { return nil }

    if currency.isFiat {
      let formatter = FiatFormatter(currency: currency, withSymbol: true)
      return formatter.attributedString(from: amount)
    } else {
      if let btcAmount = converter.amount(forCurrency: .BTC),
        let formattedAmount = BitcoinFormatter(symbolType: .attributed).attributedString(from: btcAmount) {
        return formattedAmount
      } else {
        return NSAttributedString(string: "–")
      }
    }
  }

  /// Strip out static line breaks on SE to allow width-based text wrapping
  var shouldUseStaticLineBreaks: Bool {
    return UIScreen.main.relativeSize == .tall
  }

  /// Strips static linebreaks from the string on small devices
  func sizeSensitiveMessage(from message: String) -> String {
    if shouldUseStaticLineBreaks {
      return message
    } else {
      return message.removingMultilineLineBreaks()
    }
  }

  /**
   If not nil, this string will appear in the gray rounded container instead of the breakdown amounts.
   */
  var messageLabel: String? {
    if let status = invitationStatus, status == .addressSent {
      let messageWithLineBreaks = """
      Your Bitcoin address has been sent to
      \(counterpartyDescription).
      Once approved, this transaction will be completed.
      """

      return sizeSensitiveMessage(from: messageWithLineBreaks)

    } else {
      return nil
    }
  }

  var warningMessageLabel: String? {
    if broadcastFailed {
      return "Bitcoin network failed to broadcast this transaction. Please try sending again."

    } else if let status = invitationStatus {
      switch status {
      case .canceled: return isIncoming ? "The sender has canceled this \(CKStrings.dropBitWithTrademark)." : nil // Only shows on receiver side
      case .expired:
        let messageWithLineBreaks = """
        For security reasons we can only allow 24
        hours to accept a \(CKStrings.dropBitWithTrademark). This
        DropBit has expired.
        """

        return sizeSensitiveMessage(from: messageWithLineBreaks)

      default: return nil
      }
    } else {
      return nil
    }
  }

  var breakdownSentAmountLabel: String {
    return breakdownAmountLabel(forBTCConverter: sentAmountAtCurrentConverter)
  }

  var breakdownFeeAmountLabel: String {
    return feeAmountAtCurrentConverter.flatMap({ breakdownAmountLabel(forBTCConverter: $0) }) ?? "–"
  }

  private func breakdownAmountLabel(forBTCConverter converter: CurrencyConverter) -> String {
    let btcString = stringWithSymbol(converter: converter, currency: .BTC)
    var label = btcString ?? ""

    if let usdString = stringWithSymbol(converter: converter, currency: .USD) {
      label.append(" \(usdString)")
    }

    return label
  }

  private func stringWithSymbol(converter: CurrencyConverter, currency: CurrencyCode) -> String? {
    guard let amount = converter.amount(forCurrency: currency) else { return nil }
    let formatter = TransactionAmountFormatter(currency: currency)
    return formatter.stringWithSymbol(for: amount)
  }

  var historicalCurrencyFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = CurrencyCode.USD.symbol
    formatter.maximumFractionDigits = CurrencyCode.USD.decimalPlaces
    return formatter
  }

  func historicalAmountsAttributedString() -> NSAttributedString {
    // Using bold and regular strings
    let fontSize: CGFloat = 14.0
    let color = UIColor.darkBlueText
    let attributes = TextAttributes(size: fontSize, color: color)
    let attributedString = NSMutableAttributedString.medium("", size: fontSize, color: color)

    let inviteAmount: String? = usdAtInvitedLabel
    let receivedAmount: String? = usdAtReceivedLabel

    // Amount descriptions are flipped depending on isIncoming
    switch invitationTransactionPresence {
    case .transactionOnly:
      appendReceivedAmount(receivedAmount, to: attributedString, with: attributes) { attrString in
        let description = self.isIncoming ? " when received" : " when sent"
        attrString.appendLight(description, size: fontSize, color: color)
      }

    case .invitationOnly:
      appendInviteAmount(inviteAmount, to: attributedString, with: attributes) { attrString in
        let description = " when sent"
        attrString.appendLight(description, size: fontSize, color: color)
      }

    case .both:

      if isIncoming { // Order is flipped based on isIncoming
        // Actual
        appendReceivedAmount(receivedAmount, to: attributedString, with: attributes) { attrString in
          attrString.appendLight(" when received", size: fontSize, color: color)
        }

        // Invite
        appendInviteAmount(inviteAmount, to: attributedString, with: attributes) { attrString in
          attrString.appendLight(" at send", size: fontSize, color: color)
        }

      } else {
        // Invite
        appendInviteAmount(inviteAmount, to: attributedString, with: attributes) { attrString in
          attrString.appendLight(" when sent", size: fontSize, color: color)
        }

        // Actual
        appendReceivedAmount(receivedAmount, to: attributedString, with: attributes) { attrString in
          attrString.appendLight(" when received", size: fontSize, color: color)
        }
      }

    case .neither:
      break
    }

    return attributedString
  }

  private var usdAtReceivedLabel: String? {
    guard let usdAtSent = receivedAmountAtSentConverter?.amount(forCurrency: .USD) else { return nil }
    return historicalCurrencyFormatter.string(from: usdAtSent)
  }

  private var usdAtInvitedLabel: String? {
    guard let inviteCents = transaction?.invitation?.usdAmountAtTimeOfInvitation else { return nil }
    let usdAmount = NSDecimalNumber(integerAmount: inviteCents, currency: .USD)
    return historicalCurrencyFormatter.string(from: usdAmount)
  }

  private enum InvitationTransactionPresence {
    case invitationOnly
    case transactionOnly
    case both
    case neither
  }

  private var invitationTransactionPresence: InvitationTransactionPresence {
    let actualTxExists = (transaction.flatMap { $0.txidIsActualTxid } ?? false)
    let inviteExists = (transaction?.invitation != nil)

    switch (actualTxExists, inviteExists) {
    case (true, false):   return .transactionOnly
    case (false, true):   return .invitationOnly
    case (true, true):    return .both
    case (false, false):  return .neither
    }
  }

  /// describer closure is not called if amount string is nil
  private func appendInviteAmount(
    _ inviteAmount: String?,
    to attrString: NSMutableAttributedString,
    with attributes: TextAttributes,
    describer: @escaping (NSMutableAttributedString) -> Void
    ) {
    guard let amount = inviteAmount else { return }
    if attrString.string.isNotEmpty {
      attrString.appendMedium(" ", size: attributes.size, color: attributes.color)
    }

    attrString.appendMedium(amount, size: attributes.size, color: attributes.color)

    describer(attrString)
  }

  /// describer closure is not called if amount string is nil
  private func appendReceivedAmount(
    _ receivedAmount: String?,
    to attrString: NSMutableAttributedString,
    with attributes: TextAttributes,
    describer: @escaping (NSMutableAttributedString) -> Void
    ) {
    guard let amount = receivedAmount else { return }
    if attrString.string.isNotEmpty {
      attrString.appendMedium(" ", size: attributes.size, color: attributes.color)
    }

    attrString.appendMedium(amount, size: attributes.size, color: attributes.color)

    describer(attrString)
  }

}

extension CKMTransaction {

  /// txid does not begin with a prefix (e.g. invitations with placeholder Transaction objects)
  var txidIsActualTxid: Bool {
    let isInviteOrFailed = txid.starts(with: CKMTransaction.invitationTxidPrefix) || txid.starts(with: CKMTransaction.failedTxidPrefix)
    return !isInviteOrFailed
  }

  var isCancellable: Bool {
    guard let invite = invitation else { return false }
    let cancellableStatuses: [InvitationStatus] = [.notSent, .requestSent, .addressSent]
    return (!isIncoming && cancellableStatuses.contains(invite.status))
  }

}

struct TransactionAmountFormatter {

  let currency: CurrencyCode

  func stringWithSymbol(for amount: NSDecimalNumber) -> String? {
    switch currency {
    case .USD:
      let formatter = FiatFormatter(currency: currency, withSymbol: true, showNegativeSymbol: false)
      return formatter.string(fromDecimal: amount)
    case .BTC:
      let formatter = BitcoinFormatter(symbolType: .string)
      return formatter.string(fromDecimal: amount)
    }
  }

}
