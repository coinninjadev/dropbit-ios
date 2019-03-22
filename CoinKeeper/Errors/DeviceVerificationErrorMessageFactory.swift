//
//  DeviceVerificationErrorMessageFactory.swift
//  DropBit
//
//  Created by Ben Winters on 2/16/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit

struct DeviceVerificationErrorMessageFactory {

  let phoneNumberKit = PhoneNumberKit()

  static let defaultFailureMessage = "There was a problem registering your phone number. Please verify it is correctly entered and try again."

  let verificationCodeExpired = "Verification codes expire after 5 minutes. This code has expired, please request a new code"

  let twilio = "The verification code could not be sent. Please try again later."

  func messageForResendCodeFailure(error: Error) -> String {
    if let networkError = CKNetworkError(for: error),
      case .rateLimitExceeded = networkError {
      return "Verification codes can only be requested every 30 seconds"
    } else {
      return "Oops something went wrong, try again later"
    }
  }

  func messageForCountryCodeDisabled(for phoneNumber: GlobalPhoneNumber) -> String {
    var unsupportedNumberDesc = ""
    if let region = phoneNumber.regionCode {
      let country = CKCountry(regionCode: region, kit: phoneNumberKit)
      unsupportedNumberDesc = "phone numbers in \(country.localizedName)"
    } else {
      unsupportedNumberDesc = "+\(phoneNumber.countryCode) phone numbers"
    }

    return """
      DropBit does not currently support \(unsupportedNumberDesc).
      You can still use DropBit as a Bitcoin wallet, but some features will be limited.
      Please skip the phone verification process above to continue.
      """.removingMultilineLineBreaks()
  }

}
