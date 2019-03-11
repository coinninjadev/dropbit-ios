//
//  VerifyRecoveryWordCellData.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct VerifyRecoveryWordCellData {
  let words: [String]
  let selectedIndex: Int
  let possibleWords: [String]
  weak var selectionDelegate: VerifyRecoveryWordSelectionDelegate?
}

extension VerifyRecoveryWordCellData: Equatable {
  static func == (lhs: VerifyRecoveryWordCellData, rhs: VerifyRecoveryWordCellData) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
}

extension  VerifyRecoveryWordCellData: Hashable {
  func hash(into hasher: inout Hasher) {
    words.forEach { hasher.combine($0) }
    hasher.combine(selectedIndex)
    possibleWords.forEach { hasher.combine($0) }
  }
}
