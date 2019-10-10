//
//  MockTxHistoryDetailAddressViewDelegate.swift
//  DropBitTests
//
//  Created by BJ Miller on 6/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockTxHistoryDetailAddressViewDelegate: TransactionHistoryDetailAddressViewDelegate {
  var addressViewDidSelectAddressWasCalled = false
  func addressViewDidSelectAddress(_ addressView: TransactionHistoryDetailCellAddressView) {
    addressViewDidSelectAddressWasCalled = true
  }
}
