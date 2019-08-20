//
//  CKLightningURLParser.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class CKLightningURLParser: CKParser {
  typealias Result = LightningURL

  var lightningInvoiceValidator: CompositeValidator = {
    return CompositeValidator<String>(validators: [LightningInvoiceValidator()])
  }()

  func parse(_ string: String) throws -> LightningURL? {
    if let lightningUrl = LightningURL(string: string) {
      try lightningInvoiceValidator.validate(value: lightningUrl.invoice)
      return lightningUrl
    } else {
      do {
        try lightningInvoiceValidator.validate(value: string)
        return nil
      } catch {
        throw error
      }
    }
  }

}
