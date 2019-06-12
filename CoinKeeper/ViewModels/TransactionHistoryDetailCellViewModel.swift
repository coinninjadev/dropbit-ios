//
//  TransactionHistoryDetailCellViewModel.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit
import PhoneNumberKit

/**
 Translates a Transaction object and it's relationships into a cell-displayable object.
 */
class TransactionHistoryDetailCellViewModel: TransactionHistorySummaryCellViewModel {
  var isCancellable: Bool
  var memoWasShared: Bool
  var networkFee: NSDecimalNumber?

  override init(
    transaction: CKMTransaction,
    rates: ExchangeRates,
    primaryCurrency: CurrencyCode,
    deviceCountryCode: Int?,
    kit: PhoneNumberKit
    ) {
    let fee = transaction.networkFee
    self.isCancellable = transaction.isCancellable
    self.networkFee = NSDecimalNumber(integerAmount: fee, currency: .BTC)
    self.memoWasShared = transaction.sharedPayload?.sharingDesired ?? false

    super.init(
      transaction: transaction,
      rates: rates,
      primaryCurrency: primaryCurrency,
      deviceCountryCode: deviceCountryCode,
      kit: kit
    )
  }

  /// Empty initializer override
  override init() {
    self.isCancellable = false
    self.memoWasShared = false
    super.init()
  }
}

private struct TextAttributes {
  var size: CGFloat
  var color: UIColor
}

extension TransactionHistoryDetailCellViewModel {

  var isShareable: Bool {
    return transaction?.txidIsActualTxid ?? false
  }

  var addressButtonIsActive: Bool {
    if addressStatusLabelString == nil, let receiverAddress = receiverAddress, receiverAddress.isValidBitcoinAddress() {
      return true
    }

    return false
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

  // MARK: Currency Converters
  /**
   Converters with rates for sent, received, and current dates.
   These refer to the sentAmountAtCurrentConverter for the fromCurrency, toCurrency, and current rates (if relevant).
   */

  /// The amounts from this converter are valid for both the sender and receiver
  var receivedAmountAtSentConverter: CurrencyConverter? {
    guard let amount = btcReceived, let rate = transaction?.dayAveragePrice?.doubleValue else { return nil }
    return newConverter(withRate: rate, currency: .USD, amount: amount)
  }

  var feeAmountAtCurrentConverter: CurrencyConverter? {
    guard let amount = networkFee, let rate = currentRate(for: .USD) else { return nil }
    return newConverter(withRate: rate, currency: .USD, amount: amount)
  }

  // MARK: - Labels
  ///Used for primaryAmountLabel and secondaryAmountLabel
  private var receivedAmountsConverter: CurrencyConverter {
    //fall back to sent amount if received amount / fees are not yet known
    return receivedAmountAtCurrentConverter ?? sentAmountAtCurrentConverter
  }

  var primaryAmountLabel: String? {
    return receivedAmountsConverter.amountStringWithSymbol(forCurrency: primaryCurrency)
  }

  var secondaryAmountLabel: NSAttributedString? {
    let converter = receivedAmountsConverter
    guard let secondaryCurrency = converter.otherCurrency(forCurrency: primaryCurrency) else { return nil }

    if secondaryCurrency == .BTC {
      if let btcAmount = converter.attributedStringWithSymbol(forCurrency: .BTC, ofSize: 18) {
        return btcAmount
      } else {
        return NSAttributedString(string: "–")
      }
    } else {
      return converter.attributedStringWithSymbol(forCurrency: secondaryCurrency)
    }
  }

  var currentSelectedTab: Int {
    var index: Int = 0
    if let invitationStatus = invitationStatus {
      if confirmations >= 1 {
        index = 5
      } else {
        switch invitationStatus {
        case .completed:
          if isTemporaryTransaction {
            index = 3
          } else {
            index = 4
          }
        case .addressSent:
          index = 2
        default:
          index = 1
        }
      }
    } else {
      if confirmations >= 1 {
        index = 3
      } else if isTemporaryTransaction {
        index = 1
      } else {
        index = 2
      }
    }

    return index
  }

  /// Label not visible if address exists
  var addressStatusLabelString: String? {
    guard let status = invitationStatus else { return nil }
    switch status {
    case .requestSent:  return "Waiting on Bitcoin address"
    case .addressSent:  return transaction?.invitation?.addressProvidedToSender ?? "Waiting for sender approval"
    default:            return nil
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
    let btcString = converter.amountStringWithSymbol(converter.fromAmount, .BTC)

    var label = btcString

    if let usdString = converter.amountStringWithSymbol(forCurrency: .USD) {
      label.append(" (\(usdString))")
    }

    return label
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
