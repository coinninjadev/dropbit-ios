//
//  LightningInvoiceResolver.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Result

protocol LightningInvoiceResolver: AnyObject {
  var networkManager: NetworkManagerType { get }
}

extension LightningInvoiceResolver {

  func resolveLightningInvoice(invoice: String,
                               completion: @escaping (Result<LNDecodePaymentRequestResponse, Error>) -> Void) {
    self.networkManager.decodeLightningPaymentRequest(invoice)
      .get { response in
        completion(.success(response))
      }.catch { error in
        completion(.failure(error))
    }
  }
}
