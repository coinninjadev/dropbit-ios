//
//  MockVerifyRecoveryWordsSelectionDelegate.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit

class MockVerifyRecoveryWordsSelectionDelegate: VerifyRecoveryWordSelectionDelegate {
  var wasAskedForDidSelectWord = false
  var selectedWord: String?
  var selectedCellData: VerifyRecoveryWordCellData?
  func cell(_ cell: VerifyRecoveryWordCell, didSelectWord word: String, withCellData cellData: VerifyRecoveryWordCellData) {
    wasAskedForDidSelectWord = true
    selectedWord = word
    selectedCellData = cellData
  }
}
