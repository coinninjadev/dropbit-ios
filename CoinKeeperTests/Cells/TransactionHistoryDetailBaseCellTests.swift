//
//  TransactionHistoryDetailBaseCellTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 9/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class TransactionHistoryDetailBaseCellTests: XCTestCase {
  var sut: TransactionHistoryDetailBaseCell!
  var mockCoordinator: MockTransactionHistoryDetailCellDelegate!

  override func setUp() {
    super.setUp()
    self.sut = TransactionHistoryDetailValidCell.nib().instantiate(withOwner: self, options: nil).first as? TransactionHistoryDetailValidCell
    self.sut.awakeFromNib()
    mockCoordinator = MockTransactionHistoryDetailCellDelegate()
    self.sut.delegate = mockCoordinator
  }

  override func tearDown() {
    mockCoordinator = nil
    sut = nil
    super.tearDown()
  }
}
