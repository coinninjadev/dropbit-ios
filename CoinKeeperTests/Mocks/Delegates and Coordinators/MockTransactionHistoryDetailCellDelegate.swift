//
//  MockTransactionHistoryDetailCellDelegate.swift
//  DropBitTests
//
//  Created by Ben Winters on 4/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
@testable import DropBit

class MockTransactionHistoryDetailCellDelegate: TransactionHistoryDetailCellDelegate {
  var tappedQuestionMark = false
  func didTapQuestionMarkButton(detailCell: TransactionHistoryDetailBaseCell) {
    tappedQuestionMark = true
  }

  var tappedClose = false
  func didTapClose(detailCell: TransactionHistoryDetailBaseCell) {
    tappedClose = true
  }

  var tappedTwitterShare = false
  func didTapTwitterShare(detailCell: TransactionHistoryDetailBaseCell) {
    tappedTwitterShare = true
  }

  var tappedAddress = false
  func didTapAddress(detailCell: TransactionHistoryDetailBaseCell) {
    tappedAddress = true
  }

  var tappedBottomButton = false
  var receivedAction: TransactionDetailAction?
  func didTapBottomButton(detailCell: TransactionHistoryDetailBaseCell, action: TransactionDetailAction) {
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
