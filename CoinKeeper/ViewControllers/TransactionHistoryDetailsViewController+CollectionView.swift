//
//  TransactionHistoryDetailsViewController+CollectionView.swift
//  DropBit
//
//  Created by Ben Winters on 9/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension TransactionHistoryDetailsViewController: UICollectionViewDelegate {

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: false)
    if self.delegate.uiTestIsInProgress {
      let itemCount = self.viewModel.dataSource.numberOfItems(inSection: indexPath.section)
      let newIndex = indexPath.item + 1
      guard newIndex < itemCount else { return }
      let newPath = IndexPath(item: newIndex, section: indexPath.section)
      collectionView.scrollToItem(at: newPath, at: .centeredHorizontally, animated: false)
    }
  }

}

extension TransactionHistoryDetailsViewController: UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    let hPadding: CGFloat = 2
    let itemHeight: CGFloat = self.detailCollectionViewHeight
    let itemWidth: CGFloat = self.view.frame.width - (hPadding * 2)
    return CGSize(width: itemWidth, height: itemHeight)
  }

}
