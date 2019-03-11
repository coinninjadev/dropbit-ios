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

  func didTapAddMemoButton(completion: @escaping (String) -> Void) {}
  func shouldSaveMemo(for transaction: CKMTransaction) -> Promise<Void> {
    return Promise { _ in }
  }

  func didTapQuestionMarkButton(detailCell: TransactionHistoryDetailCell, with url: URL) {}

  var tappedClose = false
  func didTapClose(detailCell: TransactionHistoryDetailCell) {
    tappedClose = true
  }

  var tappedAddress = false
  func didTapAddress(detailCell: TransactionHistoryDetailCell) {
    tappedAddress = true
  }

  var tappedBottomButton = false
  var transactionDetailAction: TransactionDetailAction = .seeDetails
  func didTapBottomButton(detailCell: TransactionHistoryDetailCell, action: TransactionDetailAction) {
    tappedBottomButton = true
    transactionDetailAction = action
  }

}
