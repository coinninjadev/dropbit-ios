//
//  TransactionDetailInvalidCellDisplayable.swift
//  DropBit
//
//  Created by Ben Winters on 9/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol TransactionDetailInvalidCellDisplayable: TransactionDetailCellDisplayable {
  var warningMessage: String? { get }
}

extension TransactionDetailInvalidCellDisplayable {
  var shouldHideWarningMessage: Bool { return warningMessage == nil }
}

protocol TransactionDetailInvalidCellViewModelType: TransactionDetailInvalidCellDisplayable, TransactionDetailCellViewModelType {

}

extension TransactionDetailInvalidCellViewModelType {

  var statusTextColor: UIColor {
    return .warningText
  }

  var directionImage: UIImage? {
    return UIImage(named: "invalidDetailIcon")
  }

  var warningMessage: String? {
    switch status {
    case .expired:
      return """
      For security reasons we can only allow
      48 hours to accept a transaction.
      This transaction has expired.
      """
    default:
      return nil
    }
  }

}
