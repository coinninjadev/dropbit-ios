//
//  TransactionSummaryCellProtocols.swift
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
  var amountProvider: TransactionAmountsProvider { get }
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
    let directionConfig = TransactionCellDirectionConfig(bgColor: accentColor, image: relevantDirectionImage)
    return SummaryCellLeadingImageConfig(twitterConfig: counterpartyConfig?.twitterConfig,
                                         directionConfig: directionConfig)
  }

  /// Transaction type icon, not an avatar
  var relevantDirectionImage: UIImage {
    guard isValidTransaction else { return invalidImage }

    if isLightningTransfer {
      return transferImage
    } else {
      switch walletTxType {
      case .lightning:  return isPendingInvoice ? lightningImage : basicDirectionImage
      case .onChain:    return basicDirectionImage
      }
    }
  }

  var accentColor: UIColor {
    guard isValidTransaction else { return .invalid }

    if isPendingInvoice {
      return .lightningBlue
    } else {
      return basicDirectionColor
    }
  }

  private var isPendingInvoice: Bool {
    guard !isLightningTransfer else { return false }
    return walletTxType == .lightning && status == .pending
  }

  var basicDirectionImage: UIImage {
    switch direction {
    case .in:   return incomingImage
    case .out:  return outgoingImage
    }
  }

  var basicDirectionColor: UIColor {
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
    case .completed:
      switch direction {
      case .in: return lightningReceivedPaidInvoiceText
      case .out: return lightningPaidInvoiceText
      }
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
    let amounts = self.amountProvider.netAtCurrentAmounts

    var btcAttributedString: NSAttributedString?
    if walletTxType == .onChain {
      btcAttributedString = BitcoinFormatter(symbolType: .attributed).attributedString(from: amounts.btc)
    }

    let signedFiatAmount = self.signedAmount(for: amounts.fiat)
    let satsText = SatsFormatter().string(fromDecimal: amounts.btc) ?? ""
    let fiatText = FiatFormatter(currency: amounts.fiatCurrency,
                                 withSymbol: true,
                                 showNegativeSymbol: true,
                                 negativeHasSpace: true).string(fromDecimal: signedFiatAmount) ?? ""

    let pillText: String = isValidTransaction ? fiatText : status.rawValue

    return SummaryCellAmountLabels(btcAttributedText: btcAttributedString,
                                   satsText: satsText,
                                   pillText: pillText,
                                   pillIsAmount: isValidTransaction)
  }

  func signedAmount(for amount: NSDecimalNumber) -> NSDecimalNumber {
    guard !amount.isNegativeNumber else { return amount }
    switch direction {
    case .in:   return amount
    case .out:  return amount.multiplying(by: NSDecimalNumber(value: -1))
    }
  }

  var lightningPaidInvoiceText: String { return "Paid Invoice" }
  var lightningReceivedPaidInvoiceText: String { return "Received" }
  var lightningUnpaidInvoiceText: String { return "Lightning Invoice" }
  var lightningWithdrawText: String { return "Lightning Withdrawal" }
  var lightningDepositText: String { return "Lightning Load" }

  var incomingImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellIncoming") }
  var outgoingImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellOutgoing") }
  var transferImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellTransfer") }
  var lightningImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellLightning") }
  var invalidImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellInvalid") }

}
