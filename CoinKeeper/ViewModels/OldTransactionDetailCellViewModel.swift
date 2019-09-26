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
    self.isCancellable = false //transaction.isCancellable
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

extension OldTransactionDetailCellViewModel {

  var imageForTransactionDirection: UIImage? {
    if transactionIsInvalidated {
      return UIImage(named: "invalidated40")
    } else {
      return isIncoming ? UIImage(named: "incoming40") : UIImage(named: "outgoing40")
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

}

extension CKMTransaction {

  /// txid does not begin with a prefix (e.g. invitations with placeholder Transaction objects)
  var txidIsActualTxid: Bool {
    let isInviteOrFailed = txid.starts(with: CKMTransaction.invitationTxidPrefix) || txid.starts(with: CKMTransaction.failedTxidPrefix)
    return !isInviteOrFailed
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
