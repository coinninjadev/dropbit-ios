//
//  RequestPayViewModel.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol RequestPayViewModelType: AnyObject {
  var bitcoinUrl: BitcoinURL { get }

  func qrImage(withSize size: CGSize) -> UIImage?
}

class RequestPayViewModel: RequestPayViewModelType {
  let bitcoinUrl: BitcoinURL
  let currencyConverter: CurrencyConverter
  let qrCodeGenerator: QRCodeGenerator

  init?(receiveAddress: String,
        currencyConverter: CurrencyConverter) {
    guard let bitcoinUrl = BitcoinURL(address: receiveAddress, amount: currencyConverter.btcAmount) else { return nil }
    self.bitcoinUrl = bitcoinUrl
    self.currencyConverter = currencyConverter
    self.qrCodeGenerator = QRCodeGenerator()
  }

  func qrImage(withSize size: CGSize) -> UIImage? {
    return qrCodeGenerator.image(from: bitcoinUrl.absoluteString, size: size)
  }
}
