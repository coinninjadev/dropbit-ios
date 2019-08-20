//
//  TransactionHistoryDetailCellDisplayable.swift
//  DropBit
//
//  Created by Ben Winters on 7/31/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

/// Provides all variable values directly necessary to configure the TransactionHistorySummaryCell UI.
/// Fixed values (colors, font sizes, etc.) are contained by the cell itself.
protocol TransactionHistorySummaryCellDisplayable {
  var direction: TransactionDirection { get }
  var statusText: String { get }
  var statusTextColor: UIColor { get }
  var counterpartyDescription: String? { get }
  var amountLabels: TransactionCellAmountLabels { get }
  var twitterConfig: DetailCellTwitterConfig? { get }
  var memo: String? { get }
  var displayDate: String { get }
}

/// Provides all variable values directly necessary to configure the TransactionHistoryDetailCell UI.
/// Fixed values (colors, font sizes, etc.) are contained by the cell itself.
protocol TransactionHistoryDetailCellDisplayable: TransactionHistorySummaryCellDisplayable {
  var progressConfig: ProgressBarConfig? { get }
  var bitcoinAddress: String? { get }
  var memoConfig: DetailCellMemoConfig? { get }
  var canAddMemo: Bool { get }
  var actionButtonConfig: DetailCellActionButtonConfig? { get }
}

extension TransactionHistoryDetailCellDisplayable {
  var directionImage: UIImage? {
    switch direction {
    case .in:   return UIImage(named: "incomingDetailIcon")
    case .out:  return UIImage(named: "outgoingDetailIcon")
    }
  }

  var statusTextColor: UIColor {
    return .lightGrayText
  }
}

protocol TransactionHistoryInvalidDetailCellDisplayable: TransactionHistoryDetailCellDisplayable {
  var status: TransactionStatus { get }
}

extension TransactionHistoryInvalidDetailCellDisplayable {

  var statusTextColor: UIColor {
    return .warning
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

struct ProgressBarConfig {
  let titles: [String]
  let stepTitles: [String]
  let width: CGFloat
  let selectedTabIndex: Int
}

struct LightningInvoiceDisplayDetails {
  let invoiceStatus: InvoiceStatus
  let qrCode: UIImage
  let request: String
  let memo: String?

  enum InvoiceStatus {
    case pending(Int) //associated value is hours remaining
    case expired
    case paid
  }

  var canRemoveFromTransactionList: Bool {
    if case .expired = invoiceStatus {
      return true
    } else {
      return false
    }
  }
}

struct DetailCellActionButtonConfig {
  let title: String
  let backgroundColor: UIColor
}

struct DetailCellMemoConfig {
  let memo: String
  let isShared: Bool
  let sharingDescription: String?
  let sharingIcon: UIImage?
}

struct DetailCellTwitterConfig {
  let avatar: UIImage
  let accessory: UIImage
  let displayHandle: String
}

/// Only one of the secondary strings should be set
struct TransactionCellAmountLabels {
  let primaryText: String
  let secondaryText: String?
  let secondaryAttributedText: NSAttributedString?
  let historicalPriceAttributedText: NSAttributedString?
}
