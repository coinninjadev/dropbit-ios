//
//  CoinNinjaUrlFactory.swift
//  DropBit
//
//  Created by Mitchell on 5/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreLocation

struct CoinNinjaUrlFactory {

  enum CoinNinjaURL {
    case bitcoin
    case seedWords
    case bitcoinSMS
    case whyBitcoin
    case dropBit
    case transaction(id: String)
    case address(id: String)
    case invoice(invoice: String)
    case faqs
    case contactUs
    case termsOfUse
    case privacyPolicy
    case detailsTooltip
    case myAddressesTooltip
    case sharedMemosTooltip
    case regularTransactionTooltip
    case dropbitTransactionTooltip
    case lightningWithdrawalTooltip
    case lightningInvoiceTooltip
    case lightningDropBitTooltip
    case adjustableFeesTooltip
    case dustProtection
    case download
    case spendBitcoinOnline
    case spendBitcoinAroundMe(CLLocationCoordinate2D)
    case spendBitcoinGiftCards
    case buyGiftCards
    case buyWithCreditCard
    case buyAtATM(CLLocationCoordinate2D)
    case dropBitMe(handle: String)
    case dropBitMeLearnMore
    case lightningUpgrade
    case dropBitAppLightningWithdrawalFees

    var domain: String {
      switch self {
      case .spendBitcoinOnline,
           .spendBitcoinAroundMe,
           .spendBitcoinGiftCards,
           .buyGiftCards,
           .buyWithCreditCard,
           .buyAtATM,
           .invoice:
        #if DEBUG
        return "https://test.coinninja.net/"
        #else
        return "https://www.coinninja.com/"
        #endif
      case .bitcoin,
           .seedWords,
           .whyBitcoin,
           .transaction,
           .address:
        return "https://www.coinninja.com/"
      case .dropBit,
           .faqs,
           .contactUs,
           .termsOfUse,
           .bitcoinSMS,
           .privacyPolicy,
           .detailsTooltip,
           .myAddressesTooltip,
           .sharedMemosTooltip,
           .dustProtection,
           .download,
           .adjustableFeesTooltip,
           .dropBitAppLightningWithdrawalFees,
           .regularTransactionTooltip,
           .dropbitTransactionTooltip,
           .lightningWithdrawalTooltip,
           .lightningInvoiceTooltip,
           .lightningDropBitTooltip,
           .lightningUpgrade:
        return "https://dropbit.app/"
      case .dropBitMe,
           .dropBitMeLearnMore:
        #if DEBUG
        return "https://test.dropbit.me/"
        #else
        return "https://dropbit.me/"
        #endif
      }
    }

    private var tooltipBreadcrumb: String {
      return "tooltips/"
    }

    var path: String {
      switch self {
      case .bitcoin:
        return "learnbitcoin"
      case .seedWords:
        return "seedwords"
      case .bitcoinSMS:
        return "dropbit"
      case .whyBitcoin:
        return "whybitcoin"
      case .dropBit:
        return "dropbit"
      case .download:
        return "download"
      case .transaction(let id):
        return "tx/\(id)"
      case .address(let id):
        return "address/\(id)"
      case .invoice(let invoice):
        return "invoices/\(invoice)"
      case .faqs:
        return "faq"
      case .contactUs:
        return "faq#contact"
      case .termsOfUse:
        return "termsofuse"
      case .privacyPolicy:
        return "privacypolicy"
      case .detailsTooltip:
        return "\(tooltipBreadcrumb)transactiondetails"
      case .myAddressesTooltip:
        return "\(tooltipBreadcrumb)myaddresses"
      case .sharedMemosTooltip:
        return "\(tooltipBreadcrumb)sharedmemos"
      case .regularTransactionTooltip:
        return "\(tooltipBreadcrumb)regulartransaction"
      case .dropbitTransactionTooltip:
        return "\(tooltipBreadcrumb)dropbittransaction"
      case .lightningWithdrawalTooltip:
        return "\(tooltipBreadcrumb)lightningwithdrawal"
      case .lightningInvoiceTooltip:
        return "\(tooltipBreadcrumb)lightninginvoice"
      case .lightningDropBitTooltip:
        return "\(tooltipBreadcrumb)lightningdropbit"
      case .dustProtection:
        return "\(tooltipBreadcrumb)dustprotection"
      case .adjustableFeesTooltip:
        return "\(tooltipBreadcrumb)fees"
      case .spendBitcoinOnline:
        return "news/webview/load-online"
      case .spendBitcoinAroundMe(let coordinate):
        return "news/webview/load-map?lat=\(coordinate.latitude)&long=\(coordinate.longitude)&type=spend"
      case .spendBitcoinGiftCards:
        return "spendbitcoin/giftcards"
      case .buyGiftCards:
        return "buybitcoin/giftcards"
      case .buyWithCreditCard:
        return "buybitcoin/creditcards"
      case .buyAtATM(let coordinate):
        return "news/webview/load-map?lat=\(coordinate.latitude)&long=\(coordinate.longitude)&type=atms"
      case .dropBitMe(let handle):
        return handle
      case .dropBitAppLightningWithdrawalFees:
        return "\(tooltipBreadcrumb)lightningwithdrawalfees"
      case .dropBitMeLearnMore:
        return ""
      case .lightningUpgrade:
        return "upgrade"
      }
    }
  }

  static func buildUrl(for url: CoinNinjaURL) -> URL? {
    return URL(string: url.domain + url.path)
  }
}
