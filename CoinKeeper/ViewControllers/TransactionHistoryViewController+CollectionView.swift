//
//  TransactionHistoryViewController+CollectionView.swift
//  DropBit
//
//  Created by Ben Winters on 7/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension TransactionHistoryViewController {

  func summaryCollectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.scrollDirection = .vertical
    return layout
  }

}

extension TransactionHistoryViewController: UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

    let transaction = frc.object(at: indexPath)
    var height: CGFloat = 66
    height += !transaction.isConfirmed ? 20 : 0
    height += (transaction.memo?.asNilIfEmpty() != nil) ? 25 : 0
    return CGSize(width: self.view.frame.width, height: height)
  }
}

extension TransactionHistoryViewController: UICollectionViewDataSource {

  func numberOfSections(in collectionView: UICollectionView) -> Int {
  return self.frc.sections?.count ?? 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    guard let sections = frc.sections else { return 0 }
    let numberOfObjects = sections[section].numberOfObjects

    return numberOfObjects
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeue(TransactionHistorySummaryCell.self, for: indexPath)
    let transaction = frc.object(at: indexPath)
    let viewModel = summaryViewModel(for: transaction)
    cell.load(with: viewModel)
    return cell
  }

}

extension TransactionHistoryViewController: UICollectionViewDelegate {

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    showDetailCollectionView(true, indexPath: indexPath, animated: true)
  }
}

// for handling refreshView animation
extension TransactionHistoryViewController: UIScrollViewDelegate {

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView.contentOffset.y < 0 else { return }
    let offset = abs(scrollView.contentOffset.y)
    refreshViewTopConstraint.constant = offset - refreshView.frame.size.height
    refreshView.animateLogo(to: scrollView.contentOffset.y)
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    refreshView.reset()
    refreshViewTopConstraint.constant = 0
  }

  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    refreshView.fireRefreshAnimationIfNecessary()

    if refreshView.shouldQueueRefresh {
      coordinationDelegate?.viewControllerAttemptedToRefreshTransactions(self)
    }
  }
}
