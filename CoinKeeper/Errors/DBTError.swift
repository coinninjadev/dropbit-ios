//
//  ProviderError.swift
//  DropBit
//
//  Created by Ben Winters on 5/21/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Moya
import LocalAuthentication

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

  enum Biometrics: DBTErrorType {
    case authenticationFailed
    case userCancel
    case systemCancel
    case lockedOut
    case notEnrolled
    case notAvailable
    case unknown

    init(code: LAError.Code) {
      switch code {
      case .authenticationFailed: self = .authenticationFailed
      case .userCancel: self = .userCancel
      case .systemCancel: self = .systemCancel
      case LAError.Code.biometryLockout: self = .lockedOut
      case LAError.Code.biometryNotEnrolled: self = .notEnrolled
      case LAError.Code.biometryNotAvailable: self = .notAvailable
      default: self = .unknown
      }
    }

    var displayMessage: String {
      switch self {
      case .authenticationFailed: return "Authentication failed"
      case .notEnrolled: return "Not enrolled in biometric authentication"
      case .notAvailable: return "Biometric authentication is not available"
      default: return "If you are enrolled in biometric authentication, please try again."
      }
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
  }

  enum OAuth: Int, DBTErrorType {
    case invalidOrExpiredToken = -11

    var errorCode: Int {
      return self.rawValue
    }

    var displayMessage: String {
      switch self {
      case .invalidOrExpiredToken:
        return "The session token is invalid or has expired. Please close and try again."
      }
    }
  }

  enum PendingInvitation: DBTErrorType {
    case noPendingInvitationExistsForID
    case noSentInvitationExistsForID
    case noAddressProvided
    case noInvoiceProvided
    case noPaymentDelegate
    case insufficientFundsForInvitationWithID(String)
    case insufficientFeeForInvitationWithID(String)

    var displayMessage: String {
      switch self {
      case .noPendingInvitationExistsForID:   return "No pending invitation exists for ID"
      case .noSentInvitationExistsForID:      return "No sent invitation exists for ID"
      case .noAddressProvided:                return "No address provided"
      case .noInvoiceProvided:                return "No invoice provided"
      case .noPaymentDelegate:                return "No payment delegate"
      case .insufficientFundsForInvitationWithID(let id):
        return "Insufficient funds for invitation with ID: \(id)"
      case .insufficientFeeForInvitationWithID(let id):
        return "Insufficient fee for invitation with ID: \(id)"
      }
    }
  }

  enum Persistence: DBTErrorType {
    case missingValue(key: String)
    case noWalletWords
    case noManagedWallet
    case noWalletManager
    case noUser
    case phoneNotVerified
    case unexpectedResult(String)
    case failedToFetch(String, Error) //object description, error returned by fetch
    case keychainWriteFailed(key: String)
    case failedToBatchDeleteWallet([NSError])

    var displayMessage: String {
      switch self {
      case .missingValue(let key):  return "Missing value for key: \(key)"
      case .noWalletWords:          return "Failed to fetch recovery words from Keychain"
      case .noManagedWallet:        return "Failed to find wallet"
      case .noWalletManager:        return "Wallet manager is nil"
      case .noUser:                 return "Failed to find user"
      case .phoneNotVerified:       return "Phone not verified. Please verify your phone number to send a DropBit."
      case .unexpectedResult(let desc): return "Fetch request returned unexpected result: \(desc)"
      case .failedToFetch(let key): return "Failed to fetch results: \(key)"
      case .keychainWriteFailed(let key): return "Failed to store value in keychain for key: \(key)"
      case .failedToBatchDeleteWallet(let nsErrors):
        var message = "Failed to batch delete wallet. Errors:"
        for nsError in nsErrors {
          message.append("\n\n\t\(nsError.debugDescription)")
        }
        return message
      }
    }

    var debugMessage: String {
      switch self {
      case .failedToFetch(let object, let error):
        let nsError = error as NSError
        return "Error fetching \(object). Error: \(nsError.debugDescription)"
      default:
        return displayMessage
      }
    }
  }


  enum SyncRoutine: String, DBTErrorType {
    case syncRoutineInProgress
    case missingRecoveryWords
    case missingWalletManager
    case notReady
    case missingWorkers
    case missingDatabaseMigrationWorker
    case missingSyncTask
    case missingQueueDelegate

    var displayTitle: String { "Sync Error" }

    var displayMessage: String {
      switch self {
      case .syncRoutineInProgress: return "Sync routine already in progress."
      case .missingSyncTask: return "Sync task not assigned"
      case .missingQueueDelegate: return "Serial queue delegate not assigned"
      default: return rawValue
      }
    }
  }

  enum System: DBTErrorType {
    case missingValue(key: String)

    var displayMessage: String {
      switch self {
      case .missingValue(let key):  return "System is missing \(key)."
      }
    }
  }

  enum TransactionData: DBTErrorType {
    case insufficientFunds
    case insufficientFee
    case noSpendableFunds

    var displayTitle: String {
      switch self {
      case .insufficientFunds: return "Insufficient Funds"
      case .insufficientFee: return "Insufficient Fee"
      case .noSpendableFunds: return "No Spendable Funds"
      }
    }

    var displayMessage: String {
      switch self {
      case .insufficientFunds:
        return "You can't send more than you have in your wallet. This may be due to unconfirmed transactions."
      case .insufficientFee:
        return "Something went wrong calculating a fee for this DropBit invitation, please try again."
      case .noSpendableFunds:
        return "This wallet has no known unspent transaction outputs."
      }
    }
  }

  enum UserRequest: DBTErrorType {
    case noData
    case noConfirmations
    case codeInvalid
    case unexpectedStatus(UserVerificationStatus)
    case userAlreadyExists(String, UserIdentityBody) //user ID, body
    case twilioError(UserResponse, UserIdentityBody)
    case resourceAlreadyExists
    case userNotVerified
    case noVerificationStatusFound

    var displayMessage: String {
      switch self {
      case .noData:                           return "No data"
      case .noConfirmations:                  return "No confirmations"
      case .resourceAlreadyExists:            return "Resource already exists"
      case .codeInvalid:                      return "Verification code was incorrect"
      case .twilioError:                      return "Received Twilio error for user"
      case .userAlreadyExists(let id, _):     return "User already exists with ID: \(id)"
      case .unexpectedStatus(let status):     return "Unexpected verification status: \(status.rawValue)"
      case .userNotVerified:                  return "Requested user is not a verified DropBit user"
      case .noVerificationStatusFound:        return "No verification status found for user"
      }
    }

    /// Check the response string for this message to determine whether to throw .codeInvalid
    static let invalidCodeMessage = "verification code invalid"

  }

  enum Wallet: DBTErrorType {
    case failedToDeactivate
    case unexpectedAddress

    var displayMessage: String {
      switch self {
      case .failedToDeactivate:
        return "Failed to deactivate existing wallet."
      case .unexpectedAddress:
        return "Address received in response does not match one of the CNBCnlibMetaAddresses provided"
      }
    }
  }

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
