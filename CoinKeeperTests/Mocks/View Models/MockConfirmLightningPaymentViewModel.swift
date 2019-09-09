//
//  MockConfirmLightningPaymentViewModel.swift
//  DropBitTests
//
//  Created by Ben Winters on 9/7/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockConfirmLightningPaymentViewModel: ConfirmLightningPaymentViewModel {

  init() {
    super.init(invoice: TestHelpers.mockLightningInvoice(),
               contact: nil,
               btcAmount: .one,
               sharedPayload: nil,
               currencyPair: CurrencyPair(primary: .BTC, fiat: .USD),
               exchangeRates: CurrencyConverter.sampleRates)
  }
}
