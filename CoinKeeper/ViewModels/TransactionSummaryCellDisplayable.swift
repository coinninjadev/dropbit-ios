//
//  TransactionCellProtocols.swift
//  DropBit
//
//  Created by Ben Winters on 7/31/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

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
