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
  var subtitleText: String? { get }
  var subtitleFont: UIFont { get }
  var subtitleColor: UIColor { get }
  var cellBackgroundColor: UIColor { get }
}

extension TransactionSummaryCellDisplayable {

  var cellBackgroundColor: UIColor { return .white }
  var shouldHideAvatarView: Bool { return leadingImageConfig.avatarConfig == nil }
  var shouldHideTwitterLogo: Bool { return leadingImageConfig.twitterConfig == nil }
  var shouldHideDirectionView: Bool { return leadingImageConfig.directionConfig == nil }
  var shouldHideSubtitleLabel: Bool { return (subtitleText ?? "").isEmpty }

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
  var amounts: TransactionAmounts { get }
  var memo: String? { get }
  var isSentToSelf: Bool { get }
  var isLightningUpgrade: Bool { get }
  var isLightningTransfer: Bool { get }
  var isPendingTransferToLightning: Bool { get }
  var isReferralBonus: Bool { get }
}

extension TransactionSummaryCellViewModelType {

  var isValidTransaction: Bool {
    return status.isValid
  }

  var leadingImageConfig: SummaryCellLeadingImageConfig {
    if let avatar = counterpartyConfig?.avatarConfig {
      var config = TransactionCellAvatarConfig(image: avatar.image)
      config.bgColor = UIColor.lightningBlue
      return SummaryCellLeadingImageConfig(avatarConfig: config)
    } else {
      let directionConfig = TransactionCellAvatarConfig(image: relevantDirectionImage, bgColor: accentColor)
      return SummaryCellLeadingImageConfig(twitterConfig: counterpartyConfig?.twitterConfig,
                                           directionConfig: directionConfig)
    }

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
      case .in:   return lightningReceivedPaidInvoiceText
      case .out:  return lightningPaidInvoiceText
      }
    default:      return lightningUnpaidInvoiceText
    }
  }

  var subtitleText: String? {
    if isPendingTransferToLightning {
      return "PENDING"
    } else if isLightningTransfer || isReferralBonus {
      return nil
    } else {
      return memo
    }
  }

  var subtitleFont: UIFont { return isPendingTransferToLightning ? .semiBold(14) : .medium(14) }
  var subtitleColor: UIColor { return isPendingTransferToLightning ? .bitcoinOrange : .darkBlueText }

  var counterpartyDescription: String? {
    if isLightningUpgrade { return lightningUpgradeText }
    if isSentToSelf { return sentToSelfText }
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
    let currentAmounts = amounts.netAtCurrent
    var btcAttributedString: NSAttributedString?
    if walletTxType == .onChain {
      btcAttributedString = BitcoinFormatter(symbolType: .image).attributedString(from: currentAmounts.btc)
    }

    let signedFiatAmount = self.signedAmount(for: currentAmounts.fiat)
    let satsText = SatsFormatter().string(fromDecimal: currentAmounts.btc) ?? ""
    let fiatText = FiatFormatter(currency: currentAmounts.fiatCurrency,
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
    case .in: return amount
    case .out:  return amount.multiplying(by: NSDecimalNumber(value: -1))
    }
  }

  var sentToSelfText: String { return "Sent to Myself" }
  var lightningPaidInvoiceText: String { return "Paid Invoice" }
  var lightningReceivedPaidInvoiceText: String { return "Received" }
  var lightningUnpaidInvoiceText: String { return "Lightning Invoice" }
  var lightningWithdrawText: String { return "Lightning Withdrawal" }
  var lightningDepositText: String { return "Lightning Load" }
  var lightningUpgradeText: String { return "Lightning Upgrade" }

  var incomingImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellIncoming") }
  var outgoingImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellOutgoing") }
  var transferImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellTransfer") }
  var lightningImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellLightning") }
  var invalidImage: UIImage { return UIImage(imageLiteralResourceName: "summaryCellInvalid") }

}
