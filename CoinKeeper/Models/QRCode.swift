//
//  QRCode.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 4/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import AVFoundation

struct QRCode {

  let rawCode: AVMetadataMachineReadableCodeObject
  let btcAmount: NSDecimalNumber?
  let address: String?
  let paymentRequestURL: URL? // BIP 72

  init?(readableObject: AVMetadataMachineReadableCodeObject) {
    guard let qrCodeString = readableObject.stringValue else { return nil }

    if let bitcoinURL = BitcoinURL(string: qrCodeString) {
      // If the `url` contains either of these parameters, we ignore any address or amount that may also be present
      if let paymentURL = bitcoinURL.components.paymentRequest {
        self.init(rawCode: readableObject, paymentURL: paymentURL)

      } else if let address = bitcoinURL.components.address {
        self.init(
          rawCode: readableObject,
          btcAmount: bitcoinURL.components.amount, // may be nil
          address: address
        )

      } else {
        return nil
      }
    } else if let lightningInvoice = LightningInvoice(string: qrCodeString) {
      self.init(rawCode: readableObject, invoice: lightningInvoice.absoluteString)
    } else {
      return nil
    }
  }

  init(rawCode: AVMetadataMachineReadableCodeObject, invoice: String) {
    self.rawCode = rawCode
    btcAmount = nil
    address = invoice
    paymentRequestURL = nil
  }

  init(rawCode: AVMetadataMachineReadableCodeObject, btcAmount: NSDecimalNumber?, address: String?, paymentURL: URL? = nil) {
    self.rawCode = rawCode
    self.btcAmount = btcAmount
    self.address = address
    self.paymentRequestURL = paymentURL
  }

  init(rawCode: AVMetadataMachineReadableCodeObject, paymentURL: URL) {
    self.rawCode = rawCode
    self.btcAmount = nil
    self.address = nil
    self.paymentRequestURL = paymentURL
  }

  func copy(withBTCAmount amount: NSDecimalNumber) -> QRCode {
    return QRCode(rawCode: self.rawCode, btcAmount: amount, address: self.address, paymentURL: self.paymentRequestURL)
  }

}
