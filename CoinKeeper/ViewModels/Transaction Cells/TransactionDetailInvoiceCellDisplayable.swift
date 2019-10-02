//
//  TransactionDetailInvoiceCellDisplayable.swift
//  DropBit
//
//  Created by Ben Winters on 10/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol TransactionDetailInvoiceCellDisplayable: TransactionSummaryCellDisplayable {

  /// Return nil if expired
  var hoursUntilExpiration: Int? { get }
  var detailAmountLabels: DetailCellAmountLabels { get }
  var lightningInvoice: String? { get }
  var displayDate: String { get }
  var tooltipType: DetailCellTooltip { get }
  var invoiceActionConfig: DetailCellActionButtonConfig { get }

  func qrImage(withSize size: CGSize) -> UIImage?
}

extension TransactionDetailInvoiceCellDisplayable {

  var invoiceIsExpired: Bool { return hoursUntilExpiration == nil }
  var shouldHideQRHistoricalContainer: Bool { return invoiceIsExpired }

}

protocol TransactionDetailInvoiceCellViewModelType: TransactionDetailCellViewModelType, TransactionDetailInvoiceCellDisplayable {

  var qrCodeGenerator: QRCodeGenerator { get }
}

extension TransactionDetailInvoiceCellViewModelType {

  func qrImage(withSize size: CGSize) -> UIImage? {
    guard let invoice = lightningInvoice else { return nil }
    return qrCodeGenerator.image(from: invoice, size: size)
  }

  var invoiceActionConfig: DetailCellActionButtonConfig {
    return DetailCellActionButtonConfig(walletTxType: .lightning, action: invoiceAction)
  }

  private var invoiceAction: TransactionDetailAction {
    if invoiceIsExpired {
      return .removeEntry
    } else {
      return .seeDetails
    }
  }

}
