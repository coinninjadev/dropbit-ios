//
//  ProviderError.swift
//  DropBit
//
//  Created by Ben Winters on 5/21/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Moya

protocol DBTErrorType: LocalizedError {
  var displayTitle: String { get }
  var displayMessage: String { get }
  var debugMessage: String { get }
}

extension DBTErrorType {

  ///Customize this to show a different title in the alert shown to the user.
  var displayTitle: String { "Error" }

  ///Supply the `displayMessage` as the default value for `localizedDescription`.
  ///Errors conforming to `DBTErrorType` can still provide their own implementation for `LocalizedError`.
  var errorDescription: String? { displayMessage }

  ///Customize this to provide more details for logging/debugging purposes.
  var debugMessage: String { displayMessage }
}

///Useful to avoid an extension on Error, which would conform all Error objects to DBTErrorType
struct DBTErrorWrapper: DBTErrorType {
  let underlying: Error
  var displayMessage: String { underlying.localizedDescription }

  fileprivate init(error: Error) {
    self.underlying = error
  }

}

struct DBTError {

  static func cast(_ error: Error) -> DBTErrorType {
    if let alreadyDBTError = error as? DBTErrorType {
      return alreadyDBTError
    } else {
      let wrappedError = DBTErrorWrapper(error: error)
      return wrappedError
    }
  }

  enum Network: DBTErrorType {
    case reachabilityFailed(_ underlying: MoyaError)
    case shouldUnverify(_ underlying: MoyaError, _ type: RecordType)
    case unexpectedStatusCode(Int)
    case unrecognizedDateFormat(timestamp: String)
    case responseMissingValue(keyPath: String)
    case userNotVerified
    case deviceUUIDMismatch
    case emptyResponse
    case recordAlreadyExists(Response) //200 on post
    case rateLimitExceeded //429
    case serverConflict //409
    case badResponse //400
    case unauthorized //401
    case recordNotFound //404
    case unknownServerError(_ underlying: MoyaError) //500
    case encodingFailed(type: String)
    case decodingFailed(type: String)
    case countryCodeDisabled
    case twilioError(Response) //server returns a successful response with 501 if Twilio responds with error
    case thunderdomeUnavailable // 503

    ///In general, rely on CoinNinjaTargetType.defaultNetworkError to decode
    ///CoinNinjaErrorResponse for CoinNinja API calls. For other APIs, fallback to this error case.
    case underlying(MoyaError)

    /// The associated response can be used as the default value if recovering from this error
    case invalidValue(keyPath: String, value: String?, response: Decodable)

    init?(for error: Error) {
      guard let networkError = error as? DBTError.Network else {
        return nil
      }

      self = networkError
    }

    var displayMessage: String {
      switch self {
      case .unrecognizedDateFormat:         return "Received date in unrecognized format."
      case .responseMissingValue(let key):  return "Response was missing value for key: \(key)."
      case .unexpectedStatusCode(let code): return "Received unexpected status code: \(code)."
      case .rateLimitExceeded:              return "Rate limit exceeded."
      case .userNotVerified:                return "User not verified."
      case .serverConflict:                 return "Current conflict with the server state."
      case .badResponse:                    return "Bad response from the server."
      case .deviceUUIDMismatch:             return "Device UUID mismatch."
      case .emptyResponse:                  return "Empty response."
      case .unauthorized:                   return "Request unauthorized."
      case .recordAlreadyExists:            return "Record already exists."
      case .recordNotFound:                 return "Record not found."
      case .encodingFailed(let type):       return "Failed to encode object of type: \(type)"
      case .decodingFailed(let type):       return "Failed to decode object of type: \(type)"
      case .countryCodeDisabled:            return "Country code not enabled"
      case .twilioError:                    return "Twilio responded with error."
      case .underlying(let error):          return error.displayMessage

      case .invalidValue(let keypath, let value, _):
        let valueDesc = value ?? "nil"
        return "Response contained an invalid value. \(keypath): \(valueDesc)"

      case .reachabilityFailed(let moyaError):
        return "Reachability failed: \(moyaError.displayMessage)"

      case .unknownServerError(let moyaError):
        return "Server error: \(moyaError.displayMessage)"

      case .shouldUnverify(let moyaError, let type):
        return "Error represents a state that requires deverifying the device, type: \(type.rawValue). \(moyaError.errorMessage ?? "unknown")"

      case .thunderdomeUnavailable:
        let description = "We are currently updating our servers. Don't worry, your funds are safe. " +
        "Please check back again shortly."
        return description
      }
    }
  }//End of Network errors

}

/// The raw value of each case matches the error description returned in the body of the error response from our API.
enum NetworkErrorIdentifier: String {
  case deviceUUIDMismatch = "device_uuid mismatch"
  case recordNotFound = "record not found"
  case timestampHeaderOffset = "timestamp header is beyond the allowed offset"
  case missingSignatureHeader = "missing signature header"
  case userIDMismatch = "user_id mismatch"
  case badSignature = "bad signature"
}

enum RecordType: String {
  case user
  case wallet
  case unknown
}

extension MoyaError: DBTErrorType {

  /// CoinKeeper API returns a description of the error in the body
  var responseDescription: String {
    if let data = self.response?.data,
      let errorString = String(data: data, encoding: .utf8) {
      return errorString
    } else {
      return self.errorDescription ?? "MoyaError.response has no description"
    }
  }

  var coinNinjaErrorResponse: CoinNinjaErrorResponse? {
    guard let data = self.response?.data else { return nil }
    return try? JSONDecoder().decode(CoinNinjaErrorResponse.self, from: data)
  }

  var displayMessage: String {
    if let coinNinjaError = coinNinjaErrorResponse {
      return coinNinjaError.displayMessage
    } else if let data = self.response?.data, let responseString = String(data: data, encoding: .utf8) {
      return responseString
    } else {
      return self.errorDescription ?? "An unknown network error occurred"
    }
  }

}
