//
//  BitcoinURL.swift
//  DropBit
//
//  Created by Mitch on 10/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct BitcoinURL {

  let components: BitcoinURLComponents
  let absoluteString: String

  static let scheme = "bitcoin"

  init?(string: String) {
    guard let comps = BitcoinURLComponents(string: string) else { return nil }
    self.components = comps
    self.absoluteString = comps.absoluteString
  }

  init?(address: String, amount: NSDecimalNumber?) {
    var comps = URLComponents()
    comps.scheme = BitcoinURL.scheme
    comps.path = address
    if let amount = amount, amount > .zero {
      comps.queryItems = [URLQueryItem(name: "amount", value: amount.stringValue)]
    } else {
      comps.queryItems = nil
    }

    guard let componentsString = comps.string,
      let bitcoinComps = BitcoinURLComponents(string: componentsString)
      else { return nil }

    self.absoluteString = componentsString
    self.components = bitcoinComps
  }

}

/// Instances are not initialized directly, create an instance of BitcoinURL instead.
struct BitcoinURLComponents {

  /// This always starts with "bitcoin:"
  fileprivate let absoluteString: String

  let address: String?
  let amount: NSDecimalNumber?

  /// Associated with the `r` or `request` query parameter
  let paymentRequest: URL?

  var addressOrPaymentRequestExists: Bool {
    return (address != nil || paymentRequest != nil)
  }

  private init(absoluteString: String, address: String?, amount: NSDecimalNumber?, paymentRequest: URL?) {
    self.absoluteString = absoluteString
    self.address = address
    self.amount = amount
    self.paymentRequest = paymentRequest
  }

  /// The string may be a full URL that starts with "bitcoin:" or it can be just the address
  /// Initialization will fail if the address is invalid
  fileprivate init?(string: String) {
    let normalizedString = BitcoinURLComponents.normalizedInputString(string)

    guard let comps = URLComponents(string: normalizedString),
      let compsString = comps.string,
      comps.scheme == BitcoinURL.scheme
      else { return nil }

    // The path/address may be empty in the case of a BIP 70 merchant payment request
    if comps.path.isNotEmpty && !comps.path.isValidBitcoinAddress() {
      return nil
    }

    var amount: NSDecimalNumber?
    var requestURL: URL?

    if let queryItems = comps.queryItems {
      if let amountString = queryItems.first(where: {$0.name == "amount"})?.value {
        amount = BitcoinURLComponents.roundedAmount(fromString: amountString) //returns nil for "0"
      }

      if let requestItem = queryItems.first(where: { $0.name == "r" || $0.name == "request"}) {
        if let urlString = requestItem.value {
          requestURL = URL(string: urlString)
        }
      }
    }

    let address: String? = (comps.path.isNotEmpty) ? comps.path : nil

    self.init(absoluteString: compsString, address: address, amount: amount, paymentRequest: requestURL)
  }

  static func roundedAmount(fromString amountString: String) -> NSDecimalNumber? {
    guard let amt = NSDecimalNumber(fromString: amountString),
      amt.isPositiveNumber else { return nil }

    let handler = NSDecimalNumberHandler(roundingMode: .down,
                                         scale: 8,
                                         raiseOnExactness: false,
                                         raiseOnOverflow: false,
                                         raiseOnUnderflow: false,
                                         raiseOnDivideByZero: false)
    return amt.rounding(accordingToBehavior: handler)
  }

  private static func normalizedInputString(_ initialString: String) -> String {
    if let bip70URL = URL(string: initialString), bip70URL.scheme == "https" {
      // handle case where user pastes the merchant's URL without the bitcoin scheme
      return BitcoinURL.scheme + ":?r=" + initialString
    } else if !initialString.contains(BitcoinURL.scheme) {
      return BitcoinURL.scheme + ":" + initialString
    } else {
      return initialString
    }
  }

}
