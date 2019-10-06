//
//  TransactionDetailInvalidCellProtocols.swift
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
    return .warning
  }

  var directionImage: UIImage? {
    return UIImage(named: "invalidDetailIcon")
  }

  var warningMessage: String? {
    if status == .failed {
      return broadcastFailedMessage

    } else if let inviteStatus = invitationStatus {
      switch inviteStatus {
      case .expired:  return expiredMessage
      case .canceled: return canceledMessage
      default:        return nil
      }
    } else {
      return nil
    }
  }

  private var broadcastFailedMessage: String {
    return "Bitcoin network failed to broadcast this transaction. Please try sending again."
  }

  private var expiredMessage: String {
    let messageWithLineBreaks = """
    For security reasons we can only allow 48
    hours to accept a \(CKStrings.dropBitWithTrademark). This
    DropBit has expired.
    """

    return sizeSensitiveMessage(from: messageWithLineBreaks)
  }

  private var canceledMessage: String? {
    isIncoming ? "The sender has canceled this \(CKStrings.dropBitWithTrademark)." : nil // Only shows on receiver side
  }

}
