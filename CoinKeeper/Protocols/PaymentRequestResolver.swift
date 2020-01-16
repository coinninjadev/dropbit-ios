//
//  PaymentRequestResolver.swift
//  DropBit
//
//  Created by Ben Winters on 12/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Result

protocol PaymentRequestResolver: AnyObject {
  var networkManager: NetworkManagerType { get }
}

extension PaymentRequestResolver {

  var paymentErrorTitle: String {
    return "Payment Request Error"
  }

  var defaultPaymentErrorMessage: String {
    return "Failed to get merchant payment request."
  }

  func resolveMerchantPaymentRequest(withURL paymentRequestURL: URL, completion: @escaping (GetMerchantPaymentRequestResult) -> Void) {
    self.networkManager.getMerchantPaymentRequest(at: paymentRequestURL) { result in
      switch result {
      case .success(let response):
        completion(.success(response))

      case .failure(let requestError):
        completion(.failure(requestError))
      }
    }
  }

}
