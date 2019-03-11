//
//  RequestPayViewModel.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol RequestPayViewModelType: AnyObject {
  var primaryCurrencyValue: String { get }
  var secondaryCurrencyValue: NSAttributedString? { get }
  var hasFundsInRequest: Bool { get }
  var bitcoinUrl: BitcoinURL { get }

  func qrImage(withSize size: CGSize) -> UIImage?
}

class RequestPayViewModel: RequestPayViewModelType {
  let bitcoinUrl: BitcoinURL
  let currencyConverter: CurrencyConverterType
  let qrCodeGenerator: QRCodeGenerator

  init?(receiveAddress: String, currencyConverter: CurrencyConverterType) {
    guard let bitcoinUrl = BitcoinURL(address: receiveAddress, amount: currencyConverter.btcValue) else { return nil }
    self.bitcoinUrl = bitcoinUrl
    self.currencyConverter = currencyConverter
    self.qrCodeGenerator = QRCodeGenerator()
  }

  var primaryCurrencyValue: String {
    return currencyConverter.fromDisplayValue
  }

  var secondaryCurrencyValue: NSAttributedString? {
    return currencyConverter.attributedStringWithSymbol(forCurrency: currencyConverter.toCurrency)
  }

  var hasFundsInRequest: Bool {
    return self.currencyConverter.fromAmount.isNotZero && self.currencyConverter.fromAmount.isNumber
  }

  func qrImage(withSize size: CGSize) -> UIImage? {
    return qrCodeGenerator.image(from: bitcoinUrl.absoluteString, size: size)
  }
}
