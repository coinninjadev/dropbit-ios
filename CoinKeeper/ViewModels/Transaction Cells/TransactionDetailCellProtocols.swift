//
//  TransactionDetailCellProtocols.swift
//  DropBit
//
//  Created by Ben Winters on 9/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

/// Provides all variable values directly necessary to configure the TransactionHistoryDetailCell UI.
/// Fixed values (colors, font sizes, etc.) are provided by the cell itself.
protocol TransactionDetailCellDisplayable: TransactionSummaryCellDisplayable {
  var directionConfig: TransactionCellDirectionConfig { get }
  var detailStatusText: String { get }
  var detailStatusColor: UIColor { get }
  var twitterConfig: TransactionCellTwitterConfig? { get }
  var counterpartyText: String? { get }
  var detailAmountLabels: DetailCellAmountLabels { get }
  var memoConfig: DetailCellMemoConfig? { get }
  var canAddMemo: Bool { get }
  var displayDate: String { get }
  var messageText: String? { get }
  var progressConfig: ProgressBarConfig? { get }
  var addressViewConfig: AddressViewConfig { get }
  var actionButtonConfig: DetailCellActionButtonConfig? { get }
  var tooltipType: DetailCellTooltip { get }
  var detailCellType: TransactionDetailCellType { get }

}

extension TransactionDetailCellDisplayable {

  var shouldHideAddressView: Bool { return isLightningTransfer }
  var shouldHideCounterpartyLabel: Bool { return counterpartyText == nil }
  var shouldHideMemoView: Bool { return shouldHideMemoLabel }
  var shouldHideAddMemoButton: Bool { return !canAddMemo }
  var shouldHideMessageLabel: Bool { return messageText == nil }
  var shouldHideProgressView: Bool { return progressConfig == nil }
  var shouldHideBottomButton: Bool { return actionButtonConfig == nil }
  var shouldHideHistoricalValuesLabel: Bool { return detailAmountLabels.historicalPriceAttributedText == nil }
  var shouldHideTwitterShareButton: Bool { return isLightningTransfer }

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

enum TransactionDetailCellType {
  case valid, invalid, invoice
}

/// Defines the properties that need to be set during initialization of the view model.
/// The inherited `...Displayable` requirements should be calculated in this
/// protocol's extension or provided by a mock view model.
protocol TransactionDetailCellViewModelType: TransactionSummaryCellViewModelType, TransactionDetailCellDisplayable {
  var date: Date { get }
  var memoIsShared: Bool { get }
  var invitationStatus: InvitationStatus? { get }
  var onChainConfirmations: Int? { get }
  var addressProvidedToSender: String? { get }
  var paymentIdIsValid: Bool { get }
}

extension TransactionDetailCellViewModelType {

  var detailCellType: TransactionDetailCellType {
    if (lightningInvoice != nil) && (status != .completed) && !isInvitation {
      return .invoice
    } else {
      return isValidTransaction ? .valid : .invalid
    }
  }

  var isIncoming: Bool {
    return direction == .in
  }

  var directionConfig: TransactionCellDirectionConfig {
    let isValidDropBit = isDropBit && isValidTransaction

    let useBasicDirection = isLightningTransfer || isValidDropBit
    if useBasicDirection {
      return TransactionCellDirectionConfig(bgColor: basicDirectionColor, image: basicDirectionImage)
    } else {
      return TransactionCellDirectionConfig(bgColor: accentColor, image: relevantDirectionImage)
    }

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
      case .lightning:  return isDropBit ? string(for: .complete) : string(for: .invoicePaid)
      }
    }
  }

  var detailStatusColor: UIColor {
    return isValidTransaction ? .darkGrayText : .warning
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

  /// This struct provides a subset of the values so that the address view doesn't hold a reference to the full object
  var addressViewConfig: AddressViewConfig {
    return AddressViewConfig(receiverAddress: receiverAddress,
                             addressProvidedToSender: addressProvidedToSender,
                             broadcastFailed: (status == .failed && walletTxType == .onChain),
                             invitationStatus: invitationStatus)
  }

  var detailAmountLabels: DetailCellAmountLabels {
    let netAtCurrent = amounts.netAtCurrent

    let btcAttributedString: NSAttributedString?
    switch walletTxType {
    case .onChain:
      btcAttributedString = BitcoinFormatter(symbolType: .attributed).attributedString(from: netAtCurrent.btc)
    case .lightning:
      let satsText = SatsFormatter().string(fromDecimal: netAtCurrent.btc) ?? ""
      btcAttributedString = NSMutableAttributedString.medium(satsText, size: 14, color: .bitcoinOrange)
    }

    let signedFiatAmount = self.signedAmount(for: netAtCurrent.fiat)
    let fiatText = FiatFormatter(currency: netAtCurrent.fiatCurrency,
                                 withSymbol: true,
                                 showNegativeSymbol: true,
                                 negativeHasSpace: false).string(fromDecimal: signedFiatAmount) ?? ""

    let secondary = btcAttributedString ?? NSAttributedString(string: "-")

    let historicalText = historicalAmountsAttributedString(fiatWhenTransacted: amounts.netWhenTransacted?.fiat,
                                                           fiatWhenInvited: amounts.netWhenInitiated?.fiat)

    return DetailCellAmountLabels(primaryText: fiatText,
                                  secondaryAttributedText: secondary,
                                  historicalPriceAttributedText: historicalText)
  }

  var memoConfig: DetailCellMemoConfig? {
    guard let memoText = memo else { return nil }
    let isSent = self.status == .completed
    return DetailCellMemoConfig(memo: memoText, isShared: memoIsShared, isSent: isSent,
                                isIncoming: isIncoming, recipientName: counterpartyText)
  }

  var canAddMemo: Bool {
    if isLightningTransfer { return false }
    if isIncoming && status != .completed { return false }
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

  var tooltipType: DetailCellTooltip {
    return isDropBit ? .dropBit : .regularOnChain
  }

  var actionButtonConfig: DetailCellActionButtonConfig? {
    guard let action = bottomButtonAction else { return nil }
    return DetailCellActionButtonConfig(walletTxType: walletTxType, action: action)
  }

  private var bottomButtonAction: TransactionDetailAction? {
    guard status != .failed else { return nil }

    if isCancellable {
      return .cancelInvitation
    } else if isShareable {
      return .seeDetails
    } else {
      return nil
    }
  }

  private var isCancellable: Bool {
    guard let status = invitationStatus else { return false }
    let cancellableStatuses: [InvitationStatus] = [.notSent, .requestSent, .addressSent]
    return (direction == .out && cancellableStatuses.contains(status))
  }

  private var isShareable: Bool {
    return paymentIdIsValid
  }

  func string(for stringId: DetailCellString) -> String {
    return stringId.rawValue
  }

  var historicalCurrencyFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = CurrencyCode.USD.symbol
    formatter.maximumFractionDigits = CurrencyCode.USD.decimalPlaces
    return formatter
  }

  private func historicalAmountsAttributedString(fiatWhenTransacted: NSDecimalNumber?, fiatWhenInvited: NSDecimalNumber?) -> NSAttributedString? {
    // Using bold and regular strings
    let fontSize: CGFloat = 14.0
    let color = UIColor.darkBlueText
    let attributes = TextAttributes(size: fontSize, color: color)
    let attributedString = NSMutableAttributedString.medium("", size: fontSize, color: color)

    let inviteAmount: String? = fiatWhenInvited.flatMap { historicalCurrencyFormatter.string(from: $0) }
    let receivedAmount: String? = fiatWhenTransacted.flatMap { historicalCurrencyFormatter.string(from: $0) }
    guard inviteAmount != nil || receivedAmount != nil else { return nil }

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
      return nil
    }

    return attributedString
  }

  private var invitationTransactionPresence: InvitationTransactionPresence {
    let actualTxExists = paymentIdIsValid
    let inviteExists = (invitationStatus != nil)
    //TODO: adjust this logic to create a new case so that historical values are shown when an invoice exists without an invitation
//    let invoiceExists = (lightningInvoice != nil)
//    let inviteOrInvoiceExists = (inviteExists || invoiceExists)

    switch (actualTxExists, inviteExists) {
    case (true, false):   return .transactionOnly
    case (false, true):   return .invitationOnly
    case (true, true):    return .both
    case (false, false):  return .neither
    }
  }

  /// describer closure is not called if amount string is nil
  private func appendInviteAmount(_ inviteAmount: String?,
                                  to attrString: NSMutableAttributedString,
                                  with attributes: TextAttributes,
                                  describer: @escaping (NSMutableAttributedString) -> Void) {
    guard let amount = inviteAmount else { return }
    if attrString.string.isNotEmpty {
      attrString.appendMedium(" ", size: attributes.size, color: attributes.color)
    }

    attrString.appendMedium(amount, size: attributes.size, color: attributes.color)

    describer(attrString)
  }

  /// describer closure is not called if amount string is nil
  private func appendReceivedAmount(_ receivedAmount: String?,
                                    to attrString: NSMutableAttributedString,
                                    with attributes: TextAttributes,
                                    describer: @escaping (NSMutableAttributedString) -> Void) {
    guard let amount = receivedAmount else { return }
    if attrString.string.isNotEmpty {
      attrString.appendMedium(" ", size: attributes.size, color: attributes.color)
    }

    attrString.appendMedium(amount, size: attributes.size, color: attributes.color)

    describer(attrString)
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

enum InvitationTransactionPresence {
  case invitationOnly
  case transactionOnly
  case both
  case neither
}

struct TextAttributes {
  var size: CGFloat
  var color: UIColor
}
