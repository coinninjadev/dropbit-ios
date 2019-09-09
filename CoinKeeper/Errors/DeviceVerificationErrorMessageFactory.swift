//
//  DeviceVerificationErrorMessageFactory.swift
//  DropBit
//
//  Created by Ben Winters on 2/16/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct DeviceVerificationErrorMessageFactory {

  static let defaultFailureMessage = "There was a problem registering your phone number. Please verify it is correctly entered and try again."

  let verificationCodeExpired = "Verification codes expire after 5 minutes. This code has expired, please request a new code"

  let twilio = "The verification code could not be sent. Please try again later."

  func messageForResendCodeFailure(error: Error) -> String {
    if let networkError = CKNetworkError(for: error),
      case .rateLimitExceeded = networkError {
      log.error(error, message: "Rate limit exceeded when verifying phone number.")
      return "Verification codes can only be requested every 30 seconds"
    } else {
      log.error(error, message: "Resend verification code failed")
      return """
        There was an error re-sending the verification code.
        This could be due to current network conditions, or the SMS provider failed to send.
        Please try again later.
        """.removingMultilineLineBreaks()
    }
  }

  func messageForCountryCodeDisabled(for phoneNumber: GlobalPhoneNumber) -> String {
    var unsupportedNumberDesc = ""
    if let region = phoneNumber.regionCode {
      let country = CKCountry(regionCode: region)
      unsupportedNumberDesc = "phone numbers in \(country.localizedName)"
    } else {
      unsupportedNumberDesc = "+\(phoneNumber.countryCode) phone numbers"
    }

    log.error("Failed to send DropBit to unsupported country: \(phoneNumber.countryCode)")
    return """
      DropBit does not currently support \(unsupportedNumberDesc).
      You can still use DropBit as a Bitcoin wallet, but some features will be limited.
      Please skip the phone verification process above to continue.
      """.removingMultilineLineBreaks()
  }

}
