//
//  TwilioError.swift
//  DropBit
//
//  Created by Ben Winters on 2/16/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum TwilioError: String {
  case failedSendingSMSVerification = "failed sending sms verification"
  case phoneNumberIsInvalid = "phone number is invalid"
  case invalidCountryCode = "invalid country code"
  case unspecified //some other Twilio error that we are not handling specifically

  init?(response: CoinNinjaErrorResponse) {
    self.init(rawValue: response.error)
  }
}
