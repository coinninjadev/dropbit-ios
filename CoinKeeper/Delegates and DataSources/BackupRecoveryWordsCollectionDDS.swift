//
//  BackupRecoveryWordsCollectionDDS.swift
//  DropBit
//
//  Created by BJ Miller on 2/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class BackupRecoveryWordsCollectionDDS: NSObject, UICollectionViewDelegate, UICollectionViewDataSource {
  let words: [String]
  private let cellDisplayedHandler: (Int) -> Void

  init(words: [String], cellDisplayedHandler: @escaping (Int) -> Void) {
    self.words = words
    self.cellDisplayedHandler = cellDisplayedHandler
  }

  private func cellData(for indexPath: IndexPath) -> BackupRecoveryWordCellData {
    let lazyData = words.lazy.enumerated().map { BackupRecoveryWordCellData(word: $1, currentIndex: $0 + 1, total: words.count) }
    return lazyData[indexPath.row]
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: BackupRecoveryWordsCell.reuseIdentifier,
      for: indexPath) as? BackupRecoveryWordsCell else { return UICollectionViewCell() }
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
