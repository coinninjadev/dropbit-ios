//
//  UserNotifiableError.swift
//  DropBit
//
//  Created by Ben Winters on 10/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol UserNotifiableError: LocalizedError {
  var recoverySuggestion: String? { get }
  var shouldAlertWithDisplayMessage: Bool { get }

  /// With some refactoring, this could handle both banners and modal alerts.
  var displayFormat: CKBannerViewKind { get }
}

extension UserNotifiableError {

  var errorDescription: String? {
    return displayMessage
  }

  var recoverySuggestion: String? {
    return nil
  }

  /// By default, if displayMessage is not nil, an alert or banner should be shown.
  var shouldAlertWithDisplayMessage: Bool {
    return true
  }

  var displayFormat: CKBannerViewKind {
    return .error
  }

  var displayMessage: String? {
    var msg = ""
    if let desc = errorDescription {
      msg = desc
    }

    if let suggestion = recoverySuggestion {
      if msg.isNotEmpty {
        msg += " "
      }
      msg += suggestion
    }

    return msg
  }

}
