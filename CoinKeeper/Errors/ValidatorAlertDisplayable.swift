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

  /// Handles casting the caught error to DBTErrorType and presenting an alert with its displayMessage
  func showValidatorAlert(for error: Error, title: String) {
    let dbtError = DBTError.cast(error)
    if let alert = alertManager?.defaultAlert(withTitle: title, description: dbtError.displayMessage) {
      self.present(alert, animated: true, completion: nil)
    }
  }

}
