//
//  NetworkManager+MerchantPaymentRequestRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 11/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Result

protocol MerchantPaymentRequestRequestable: AnyObject {
  /// Pass in the URL included for the r or request parameter of a BIP 70 QR code
  func getMerchantPaymentRequest(at url: URL, completion: @escaping (Result<MerchantPaymentRequestResponse, MerchantPaymentRequestError>) -> Void)
}

extension NetworkManager: MerchantPaymentRequestRequestable {

  func getMerchantPaymentRequest(at url: URL, completion: @escaping (Result<MerchantPaymentRequestResponse, MerchantPaymentRequestError>) -> Void) {
    var urlRequest = URLRequest(url: url)
    urlRequest.addValue("application/payment-request", forHTTPHeaderField: "Accept")
    let session = URLSession.shared
    let task = session.dataTask(with: urlRequest) { (data, _, error) in
      if let data = data {
        do {
          let paymentResponse = try MerchantPaymentRequestResponse.decodeResponse(from: data)
          let validatedResponse = try MerchantPaymentRequestResponse.validateResponse(paymentResponse)
          completion(.success(validatedResponse))
        } catch let err {
          if let requestError = err as? MerchantPaymentRequestError {
            completion(.failure(requestError))
          } else if let responseAsString = String(data: data, encoding: .utf8) {
            let responseAsError = MerchantPaymentRequestError.serverErrorMessage(responseAsString)
            completion(.failure(responseAsError))
          } else {
            completion(.failure(.underlying(err)))
          }
        }
      } else if let err = error {
        completion(.failure(.underlying(err)))
      }
    }
    task.resume()
  }

}
