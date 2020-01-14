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

  /// Handles casting the caught error to DisplayableError and presenting an alert with its displayMessage
  func showValidatorAlert(for error: Error, title: String) {
    let displayableError = DisplayableErrorWrapper.wrap(error)
    if let alert = alertManager?.defaultAlert(withTitle: title, description: displayableError.displayMessage) {
      self.present(alert, animated: true, completion: nil)
    }
  }

}
