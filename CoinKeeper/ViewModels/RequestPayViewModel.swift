//
//  RequestPayViewModel.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class RequestPayViewModel: CurrencySwappableEditAmountViewModel {

  let bitcoinUrl: BitcoinURL
  let qrCodeGenerator: QRCodeGenerator

  init?(receiveAddress: String, viewModel: CurrencySwappableEditAmountViewModel) {
    guard let bitcoinUrl = BitcoinURL(address: receiveAddress, amount: viewModel.fromAmount) else { return nil }
    self.bitcoinUrl = bitcoinUrl
    self.qrCodeGenerator = QRCodeGenerator()
    super.init(viewModel: viewModel)
  }

  func qrImage(withSize size: CGSize) -> UIImage? {
    return qrCodeGenerator.image(from: bitcoinUrl.absoluteString, size: size)
  }
}
