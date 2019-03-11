//
//  VerifyRecoveryWordsViewModel.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CommonCrypto

protocol VerifyRecoveryWordsResultDelegate: AnyObject {
  func firstMatchFound()
  func secondMatchFound()
  func errorFound()
  func fatalErrorFound()
}

protocol VerifyRecoveryWordsViewModelType: AnyObject {
  init(words: [String], resultDelegate: VerifyRecoveryWordsResultDelegate)
  func dataObjectsForVerification(withDelegate delegate: VerifyRecoveryWordSelectionDelegate) -> [VerifyRecoveryWordCellData]
  func checkMatch(forWord word: String, cellData: VerifyRecoveryWordCellData)
}

class VerifyRecoveryWordsViewModel: VerifyRecoveryWordsViewModelType {
  private var recoveryWords: [String]
  private var firstIndex: Int?, secondIndex: Int?
  private weak var resultDelegate: VerifyRecoveryWordsResultDelegate?

  required init(words: [String], resultDelegate: VerifyRecoveryWordsResultDelegate) {
    self.recoveryWords = words
    self.resultDelegate = resultDelegate
  }

  private func randomIndexesForVerification() -> [Int] {
    guard firstIndex == nil, secondIndex == nil else { return [firstIndex, secondIndex].compactMap { $0 } }
    let max = recoveryWords.count
    firstIndex = Int(arc4random_uniform(UInt32(max)))
    repeat {
      secondIndex = Int(arc4random_uniform(UInt32(max)))
    } while secondIndex == firstIndex

    return [firstIndex, secondIndex].compactMap { $0 }
  }

  private func selectedWord(for index: Int) -> String? {
    guard (0..<recoveryWords.count) ~= index else { return nil }
    return recoveryWords[index]
  }

  private func possibleWords(withSelectedIndex index: Int) -> [String] {
    guard let word = selectedWord(for: index) else { return [] }
    return recoveryWords
      .filter { $0 != word }
      .shuffled()[0...3].map { $0 }  // the [0...3] syntax returns an array slice, so the map converts it to a [String]
      .appending(element: word)
      .shuffled()
  }

  func dataObjectsForVerification(withDelegate delegate: VerifyRecoveryWordSelectionDelegate) -> [VerifyRecoveryWordCellData] {
    return randomIndexesForVerification().map { (index) -> VerifyRecoveryWordCellData in
      let possibleWords = self.possibleWords(withSelectedIndex: index)
      return VerifyRecoveryWordCellData(
        words: recoveryWords,
        selectedIndex: index,
        possibleWords: possibleWords,
        selectionDelegate: delegate
      )
    }
  }

  enum WordStatus: Int {
    case firstWord, secondWord
  }

  private var matchErrorCount = 0
  private let maxErrorCount = 3
  func checkMatch(forWord word: String, cellData: VerifyRecoveryWordCellData) {
    let wordStatus: WordStatus = (cellData.selectedIndex == firstIndex) ? .firstWord : .secondWord
    if word == selectedWord(for: cellData.selectedIndex) {
      matchErrorCount = 0
      switch wordStatus {
      case .firstWord: resultDelegate?.firstMatchFound()
      case .secondWord: resultDelegate?.secondMatchFound()
      }
    } else {
      matchErrorCount += 1
      if matchErrorCount == maxErrorCount {
        resultDelegate?.fatalErrorFound()
      } else {
        resultDelegate?.errorFound()
      }
    }
  }
}
