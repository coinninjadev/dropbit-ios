//
//  CreateRecoveryWordsCollectionDDS.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class CreateRecoveryWordsCollectionDDS: NSObject, UICollectionViewDelegate, UICollectionViewDataSource {
  let words: [String]
  private let cellDisplayedHandler: (Int) -> Void

  init(words: [String], cellDisplayedHandler: @escaping (Int) -> Void) {
    self.words = words
    self.cellDisplayedHandler = cellDisplayedHandler
  }

  private func cellData(for indexPath: IndexPath) -> CreateRecoveryWordCellData {
    let lazyData = words.lazy.enumerated().map { CreateRecoveryWordCellData(word: $1, currentIndex: $0 + 1, total: words.count) }
    return lazyData[indexPath.row]
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: CreateRecoveryWordsCell.reuseIdentifier,
      for: indexPath) as? CreateRecoveryWordsCell else { return UICollectionViewCell() }
    cell.load(with: cellData(for: indexPath))
    return cell
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return words.count
  }

  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    cellDisplayedHandler(indexPath.row)
  }
}
