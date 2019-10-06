//
//  MockTransactionHistoryDetailCellDelegate.swift
//  DropBitTests
//
//  Created by Ben Winters on 4/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
import UIKit
@testable import DropBit

class MockTransactionHistoryDetailCellDelegate: TransactionHistoryDetailCellDelegate {

  var tappedQuestionMark = false
  var receivedTooltip: DetailCellTooltip?
  func didTapQuestionMarkButton(detailCell: UICollectionViewCell, tooltip: DetailCellTooltip) {
    tappedQuestionMark = true
    receivedTooltip = tooltip
  }

  var tappedClose = false
  func didTapClose(detailCell: UICollectionViewCell) {
    tappedClose = true
  }

  var tappedTwitterShare = false
  func didTapTwitterShare(detailCell: TransactionHistoryDetailBaseCell) {
    tappedTwitterShare = true
  }

  var tappedAddress = false
  func didTapAddressLinkButton(detailCell: TransactionHistoryDetailBaseCell) {
    tappedAddress = true
  }

  var tappedInvoice = false
  func didTapCopyInvoiceButton(detailCell: TransactionHistoryDetailInvoiceCell) {
    tappedInvoice = true
  }

  var tappedBottomButton = false
  var receivedAction: TransactionDetailAction?
  func didTapBottomButton(detailCell: UICollectionViewCell, action: TransactionDetailAction) {
    tappedBottomButton = true
    receivedAction = action
  }

  var tappedAddMemo = false
  func didTapAddMemoButton(detailCell: TransactionHistoryDetailBaseCell) {
    tappedAddMemo = true
  }

  func shouldSaveMemo(for transaction: CKMTransaction) -> Promise<Void> {
    return Promise { _ in }
  }
}
