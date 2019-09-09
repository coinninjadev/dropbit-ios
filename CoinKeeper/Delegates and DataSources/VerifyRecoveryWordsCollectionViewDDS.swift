//
//  VerifyRecoveryWordsCollectionViewDDS.swift
//  DropBit
//
//  Created by BJ Miller on 3/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class VerifyRecoveryWordsCollectionViewDDS: NSObject {
  private let dataObjects: [VerifyRecoveryWordCellData]

  init(dataObjects: [VerifyRecoveryWordCellData]) {
    self.dataObjects = dataObjects
  }
}

extension VerifyRecoveryWordsCollectionViewDDS: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return dataObjects.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: VerifyRecoveryWordCell.reuseIdentifier,
      for: indexPath) as? VerifyRecoveryWordCell
      else { return UICollectionViewCell() }
    cell.load(with: dataObjects[indexPath.item])
    return cell
  }
}
