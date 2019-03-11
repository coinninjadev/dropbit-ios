//
//  ValidatorAlertDisplayable.swift
//  DropBit
//
//  Created by Ben Winters on 11/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol ValidatorAlertDisplayable: AnyObject {
  var alertManager: AlertManagerType? { get }
}

extension ValidatorAlertDisplayable where Self: UIViewController {

  /// Handles casting the caught error to ValidatorTypeError and presenting an alert with its displayMessage
  func showValidatorAlert(for error: Error, title: String) {
    var message = error.localizedDescription

    if let validationError = error as? ValidatorTypeError, let vMessage = validationError.displayMessage {
      message = vMessage
    } else if let parsingError = error as? CKRecipientParserError {
      message = parsingError.localizedDescription
    }

    if let alert = alertManager?.defaultAlert(withTitle: title, description: message) {
      self.present(alert, animated: true, completion: nil)
    }
  }

}
