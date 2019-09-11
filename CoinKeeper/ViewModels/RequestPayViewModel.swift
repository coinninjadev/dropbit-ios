//
//  RequestPayViewModel.swift
//  DropBit
//
//  Created by BJ Miller on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class RequestPayViewModel: CurrencySwappableEditAmountViewModel {

  var receiveAddress: String
  let qrCodeGenerator = QRCodeGenerator()
  var lightningInvoice: LNCreatePaymentRequestResponse?

  init(receiveAddress: String, amountViewModel: CurrencySwappableEditAmountViewModel) {
    self.receiveAddress = receiveAddress
    super.init(viewModel: amountViewModel)
  }

  var bitcoinURL: BitcoinURL? {
    return BitcoinURL(address: receiveAddress, amount: btcAmount)
  }

  func qrImage(withSize size: CGSize) -> UIImage? {
    switch walletTransactionType {
    case .lightning:
      guard let invoice = lightningInvoice else { return nil }
      return qrCodeGenerator.image(from: invoice.request, size: size)
    case .onChain:
      guard let url = bitcoinURL else { return nil }
      return qrCodeGenerator.image(from: url.absoluteString, size: size)
    }
  }
}
