//
//  MerchantPaymentRequestResponse.swift
//  DropBit
//
//  Created by Ben Winters on 11/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum MerchantPaymentRequestError: DisplayableError {
  case expired(Date)
  case incorrectCurrency(String)
  case incorrectNetwork(String)
  case missingOutput
  case underlying(Error)
  case invalidURL(URL, String)

  /// Useful when the server returns the error message as the response data
  case serverErrorMessage(String)

  var displayMessage: String {
    errorDescription ?? localizedDescription
  }

  var errorDescription: String? {
    let generalErrorPrefix = "There was an error with the payment request:"
    let messagePrefix = "The payment request you scanned"
    switch self {
    case .expired(let expiredAt):
      let expiredAtDesc = CKDateFormatter.displayConcise.string(from: expiredAt)
      if expiredAt < Date() {
        return "\(messagePrefix) has expired (\(expiredAtDesc)). Please refresh the request and scan it again."
      } else {
        return """
          \(messagePrefix) will expire very soon (\(expiredAtDesc)). To ensure the transaction has enough
          time to process, please refresh the request and scan it again.
          """.removingMultilineLineBreaks()
      }
    case .incorrectCurrency(let currency):
      return "\(messagePrefix) is for \(currency). DropBit currently only supports BTC transactions."

    case .incorrectNetwork(let network):
      return "\(messagePrefix) is for the \(network) network. It should be on the main network."

    case .missingOutput:
      return "\(messagePrefix) did not include the receive address and/or amount."

    case .serverErrorMessage(let message):
      return "\(generalErrorPrefix) \(message)"

    case .underlying(let error):
      return "\(generalErrorPrefix) \(error.localizedDescription)"
    case .invalidURL(let url, let responseString):
      let cleanedResponse = responseString.stringByStandardizingWhitespaces()
      let charLimit = 50
      let truncatedResponse = cleanedResponse.prefix(charLimit)
      let trailingChars = cleanedResponse.count > charLimit ? "..." : ""

      return "This URL is invalid for sending payments: \n\n\(url.absoluteString) \n\n\(truncatedResponse)\(trailingChars)"
    }
  }
}

struct MerchantPaymentRequestResponse: ResponseDecodable {

  let network: String
  let currency: String
  let requiredFeeRate: Double
  let outputs: [MerchantPaymentRequestOutput]
  let time: Date
  let expires: Date
  let memo: String?
  let paymentUrl: String
  let paymentId: String

  static var sampleJSON: String {
    return """
    {
    "network": "main",
    "currency": "BTC",
    "requiredFeeRate": 48.297,
    "outputs": [\(MerchantPaymentRequestOutput.sampleJSON)],
    "time": "2018-11-15T15:43:29.636Z",
    "expires": "2018-11-15T15:58:29.636Z",
    "memo": "Payment request for BitPay invoice GUGA7vbBSaY9F8YDcGUpQf for merchant Electronic Frontier Foundation",
    "paymentUrl": "https://bitpay.com/i/GUGA7vbBSaY9F8YDcGUpQf",
    "paymentId": "GUGA7vbBSaY9F8YDcGUpQf"
    }
    """
  }

  static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(CKDateFormatter.rfc3339Decoding)
    return decoder
  }

  static func decodeResponse(from data: Data) throws -> MerchantPaymentRequestResponse {
    return try decoder.decode(MerchantPaymentRequestResponse.self, from: data)
  }

  static func validateResponse(_ response: MerchantPaymentRequestResponse) throws -> MerchantPaymentRequestResponse {
    guard response.expires > Date().addingTimeInterval(60) else {
      throw MerchantPaymentRequestError.expired(response.expires)
    }

    guard response.currency == "BTC" else {
      throw MerchantPaymentRequestError.incorrectCurrency(response.currency)
    }

    guard response.network == "main" else {
      throw MerchantPaymentRequestError.incorrectNetwork(response.network)
    }

    guard let output = response.outputs.first, output.amount > 0, output.address.isNotEmpty else {
      throw MerchantPaymentRequestError.missingOutput
    }

    let stringValidatedResponse = try response.validateStringValues()

    return stringValidatedResponse
  }

  static var requiredStringKeys: [KeyPath<MerchantPaymentRequestResponse, String>] {
    return [\.network, \.currency]
  }

  static var optionalStringKeys: [WritableKeyPath<MerchantPaymentRequestResponse, String?>] {
    return []
  }

}

struct MerchantPaymentRequestOutput: ResponseDecodable {

  let amount: Int
  let address: String

  static var sampleJSON: String {
    return """
    {
    "amount": 1007100,
    "address": "14ePihNUY22FpCD7Tk1L9JfLMFKD1oKrDq"
    }
    """
  }

  static func validateResponse(_ response: MerchantPaymentRequestOutput) throws -> MerchantPaymentRequestOutput {

    return response
  }

  static var requiredStringKeys: [KeyPath<MerchantPaymentRequestOutput, String>] {
    return [\.address]
  }

  static var optionalStringKeys: [WritableKeyPath<MerchantPaymentRequestOutput, String?>] {
    return []
  }

}
