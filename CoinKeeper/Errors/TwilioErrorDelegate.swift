//
//  TwilioErrorDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 4/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum TwilioErrorRoute: String {
  case createUser
  case resendVerification
  case createAddressRequest
}

protocol TwilioErrorDelegate: AnyObject {
  func didReceiveTwilioError(for phoneNumber: String, route: TwilioErrorRoute)
}
