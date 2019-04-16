//
//  CoinNinjaUrlFactory.swift
//  CoinKeeper
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
    case faqs
    case contactUs
    case termsOfUse
    case privacyPolicy
    case detailsTooltip
    case myAddressesTooltip
    case sharedMemosTooltip
    case regularTransactionTooltip
    case dropbitTransactionTooltip
    case dustProtection
    case download
    case spendBitcoinOnline
    case spendBitcoinAroundMe(CLLocationCoordinate2D)
    case spendBitcoinGiftCards
    case buyGiftCards
    case buyWithCreditCard
    case buyAtATM(CLLocationCoordinate2D)

    var domain: String {
      switch self {
      case .bitcoin,
           .seedWords,
           .whyBitcoin,
           .transaction,
           .address,
           .spendBitcoinOnline,
           .spendBitcoinAroundMe,
           .spendBitcoinGiftCards,
           .buyGiftCards,
           .buyWithCreditCard,
           .buyAtATM:
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
           .regularTransactionTooltip,
           .dropbitTransactionTooltip:
        return "https://dropbit.app/"
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
      case .dustProtection:
        return "\(tooltipBreadcrumb)dustprotection"
      case .spendBitcoinOnline:
        return "spendbitcoin/online"
      case .spendBitcoinAroundMe(let coordinate):
        return "spendbitcoin/aroundme?lat=\(coordinate.latitude)&long=\(coordinate.longitude)"
      case .spendBitcoinGiftCards:
        return "spendbitcoin/giftcards"
      case .buyGiftCards:
        return "buybitcoin/giftcards"
      case .buyWithCreditCard:
        return "buybitcoin/creditcards"
      case .buyAtATM(let coordinate):
        return "buybitcoin/map?lat=\(coordinate.latitude)&long=\(coordinate.longitude)"
      }
    }
  }

  static func buildUrl(for url: CoinNinjaURL) -> URL? {
    return URL(string: url.domain + url.path)
  }
}
