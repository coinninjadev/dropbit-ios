//
//  QRCode.swift
//  DropBit
//
//  Created by Mitchell Malleo on 4/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import AVFoundation

struct OnChainQRCode {

  let btcAmount: NSDecimalNumber?
  let address: String?
  let paymentRequestURL: URL? // BIP 72

  init?(string: String) {
    guard let bitcoinURL = BitcoinURL(string: string) else { return nil }

    // If the `url` contains either of these parameters, we ignore any address or amount that may also be present
    if let paymentURL = bitcoinURL.components.paymentRequest {
      self.init(paymentURL: paymentURL)

    } else if let address = bitcoinURL.components.address {
      self.init(
        btcAmount: bitcoinURL.components.amount, // may be nil
        address: address
      )

    } else {
      return nil
    }
  }

  init(invoice: String) {
    btcAmount = nil
    address = invoice
    paymentRequestURL = nil
  }

  init(btcAmount: NSDecimalNumber?, address: String?, paymentURL: URL? = nil) {
    self.btcAmount = btcAmount
    self.address = address
    self.paymentRequestURL = paymentURL
  }

  init(paymentURL: URL) {
    self.btcAmount = nil
    self.address = nil
    self.paymentRequestURL = paymentURL
  }

  func copy(withBTCAmount amount: NSDecimalNumber) -> OnChainQRCode {
    return OnChainQRCode(btcAmount: amount, address: self.address, paymentURL: self.paymentRequestURL)
  }

}
