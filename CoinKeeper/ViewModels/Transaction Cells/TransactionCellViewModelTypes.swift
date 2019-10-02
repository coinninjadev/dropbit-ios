//
//  TransactionCellViewModelTypes.swift
//  DropBit
//
//  Created by Ben Winters on 9/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

enum TransactionDirection: String {
  case `in`, out

  init(lnDirection: CKMLNTransactionDirection) {
    switch lnDirection {
    case .in:   self = .in
    case .out:  self = .out
    }
  }
}

enum TransactionStatus: String {
  case pending
  case broadcasting
  case completed
  case canceled
  case expired
  case failed
}

enum LightningTransferType {
  case deposit, withdraw
}

struct TransactionAmountDetails {
  let btcAmount: NSDecimalNumber
  let currencyPair: CurrencyPair
  let exchangeRates: ExchangeRates
  let fiatWhenInvited: NSDecimalNumber?
  let fiatWhenTransacted: NSDecimalNumber?

  init(btcAmount: NSDecimalNumber,
       fiatCurrency: CurrencyCode,
       exchangeRates: ExchangeRates,
       fiatWhenInvited: NSDecimalNumber? = nil,
       fiatWhenTransacted: NSDecimalNumber? = nil) {
    self.currencyPair = CurrencyPair(primary: .BTC, fiat: fiatCurrency)
    self.exchangeRates = exchangeRates
    self.btcAmount = btcAmount
    self.fiatWhenInvited = fiatWhenInvited
    self.fiatWhenTransacted = fiatWhenTransacted
  }

  init(fiatAmount: NSDecimalNumber,
       fiatCurrency: CurrencyCode,
       exchangeRates: ExchangeRates,
       fiatWhenInvited: NSDecimalNumber? = nil,
       fiatWhenTransacted: NSDecimalNumber? = nil) {
    let fiatCurrencyPair = CurrencyPair(primary: fiatCurrency, fiat: fiatCurrency)
    let converter = CurrencyConverter(rates: exchangeRates,
                                      fromAmount: fiatAmount,
                                      currencyPair: fiatCurrencyPair)
    self.init(btcAmount: converter.btcAmount,
              fiatCurrency: fiatCurrency,
              exchangeRates: exchangeRates,
              fiatWhenInvited: fiatWhenInvited,
              fiatWhenTransacted: fiatWhenTransacted)
  }
}

struct ProgressBarConfig {
  let titles: [String]
  let stepTitles: [String]
  let width: CGFloat
  let selectedTab: Int
}

typealias Hours = Int
struct LightningInvoiceDisplayDetails {
  let invoiceStatus: InvoiceStatus
  let qrCode: UIImage
  let request: String
  let memo: String?

  enum InvoiceStatus {
    case pending(Hours)
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

enum TransactionDetailAction: Int {
  case seeDetails = 1 //UIButton.tag defaults to 0
  case cancelInvitation
  case removeEntry

  var buttonTitle: String {
    switch self {
    case .cancelInvitation:   return "CANCEL DROPBIT"
    case .seeDetails:         return "DETAILS"
    case .removeEntry:        return "REMOVE FROM TRANSACTION LIST"
    }
  }
}

struct DetailCellActionButtonConfig {
  let walletTxType: WalletTransactionType
  let action: TransactionDetailAction

  var title: String {
    return action.buttonTitle
  }

  var backgroundColor: UIColor {
    switch action {
    case .cancelInvitation:
      return .darkPeach
    case .seeDetails:
      switch walletTxType {
      case .lightning:  return .lightningBlue
      case .onChain:    return .bitcoinOrange
      }
    }
  }

  var buttonTag: Int {
    return action.rawValue
  }
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

  init?(failableWithName displayName: String?, displayPhoneNumber: String?, twitterConfig: TransactionCellTwitterConfig?) {
    guard (displayName != nil) || (displayPhoneNumber != nil) || (twitterConfig != nil) else { return nil }
    self.displayName = displayName
    self.displayPhoneNumber = displayPhoneNumber
    self.twitterConfig = twitterConfig
  }

}

struct TransactionCellTwitterConfig {
  let avatar: UIImage?
  let displayHandle: String
  let displayName: String

  init(avatar: UIImage?,
       displayHandle: String,
       displayName: String) {
    self.avatar = avatar
    self.displayHandle = displayHandle
    self.displayName = displayName
  }

  init(contact: CKMTwitterContact) {
    self.avatar = contact.profileImageData.flatMap { UIImage(data: $0) }
    self.displayHandle = contact.formattedScreenName
    self.displayName = contact.displayName
  }
}

struct SummaryCellAmountLabels {
  let btcAttributedText: NSAttributedString? //may be lightning or on-chain amount
  let satsText: String //this is always available, btcAttributedText takes precedence if set
  let pillText: String //may be amount or status description
  let pillIsAmount: Bool
}

struct TransactionCellDirectionConfig {
  let bgColor: UIColor
  let image: UIImage
}

struct TransactionCellAvatarConfig {
  let image: UIImage
}

struct SummaryCellLeadingImageConfig {
  let avatarConfig: TransactionCellAvatarConfig?
  let directionConfig: TransactionCellDirectionConfig?

  /// Falls back to use the directionConfig if twitterConfig is missing image data
  init(twitterConfig: TransactionCellTwitterConfig?,
       directionConfig: TransactionCellDirectionConfig) {
    if let avatarImage = twitterConfig?.avatar {
      self.avatarConfig = TransactionCellAvatarConfig(image: avatarImage)
      self.directionConfig = nil
    } else {
      self.avatarConfig = nil
      self.directionConfig = directionConfig
    }
  }

}

/// Only one of the secondary strings should be set
struct DetailCellAmountLabels {
  let primaryText: String
  let secondaryAttributedText: NSAttributedString
  let historicalPriceAttributedText: NSAttributedString?
}
