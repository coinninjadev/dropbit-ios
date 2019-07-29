//
//  RequestPayViewModel.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class RequestPayViewModel: CurrencySwappableEditAmountViewModel {

  var receiveAddress: String
  let qrCodeGenerator = QRCodeGenerator()

  init(receiveAddress: String, viewModel: CurrencySwappableEditAmountViewModel) {
    self.receiveAddress = receiveAddress
    super.init(viewModel: viewModel)
  }

  var bitcoinURL: BitcoinURL? {
    return BitcoinURL(address: receiveAddress, amount: btcAmount)
  }

  func qrImage(withSize size: CGSize) -> UIImage? {
    guard let url = bitcoinURL else { return nil }
    return qrCodeGenerator.image(from: url.absoluteString, size: size)
  }
}
