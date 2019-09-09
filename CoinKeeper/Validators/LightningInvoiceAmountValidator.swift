//
//  LightningInvoiceAmountValidator.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/9/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class LightningInvoiceAmountValidator: ValidatorType<Money> {

  static let lightningReloadThreshholdMax = Money(amount: NSDecimalNumber(value: 500), currency: .USD)

  override func validate(value: Money) throws {
    
  }
}
