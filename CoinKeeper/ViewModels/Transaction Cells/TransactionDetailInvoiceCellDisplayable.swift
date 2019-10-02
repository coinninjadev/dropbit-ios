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
  var qrCodeImage: UIImage { get }
  var encodedInvoice: String { get }
  var displayDate: String { get }
  var tooltipType: DetailCellTooltip { get }
  var actionButtonConfig: DetailCellActionButtonConfig { get }

}

extension TransactionDetailInvoiceCellDisplayable {

  var invoiceIsExpired: Bool { return hoursUntilExpiration == nil }
  var shouldHideQRHistoricalContainer: Bool { return invoiceIsExpired }

}
