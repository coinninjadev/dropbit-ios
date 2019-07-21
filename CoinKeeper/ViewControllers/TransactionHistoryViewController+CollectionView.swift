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

  var detailCollectionViewHeight: CGFloat {
    return self.view.frame.height
  }

  func summaryCollectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.scrollDirection = .vertical
    return layout
  }

  func detailCollectionViewLayout(withHorizontalPadding hPadding: CGFloat) -> UICollectionViewFlowLayout {
    let layout = HorizontallyPaginatedCollectionViewLayout()
    let itemHeight = detailCollectionViewHeight
    let itemWidth: CGFloat = self.view.frame.width - (hPadding * 2)
    layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
    layout.minimumInteritemSpacing = 0
    layout.minimumLineSpacing = 4
    layout.scrollDirection = .horizontal
    return layout
  }

}

extension TransactionHistoryViewController: UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    guard collectionView == summaryCollectionView else { return CGSize(width: collectionView.frame.width - 16, height: collectionView.frame.height) }
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
    switch collectionView {
    case summaryCollectionView:
      guard let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: TransactionHistorySummaryCell.reuseIdentifier,
        for: indexPath) as? TransactionHistorySummaryCell
        else { return UICollectionViewCell() }

      let transaction = frc.object(at: indexPath)

      let viewModel = summaryViewModel(for: transaction)

      cell.load(with: viewModel)

      return cell

    case detailCollectionView:
      let vm = detailViewModel(at: indexPath)

      if let invitation = vm.transaction?.invitation {
        switch invitation.status {
        case .canceled, .expired:
          let cell = detailCollectionView.dequeue(TransactionHistoryDetailInvalidCell.self, for: indexPath)
          cell.load(with: vm, delegate: self)
          return cell
        default:
          let cell = detailCollectionView.dequeue(TransactionHistoryDetailValidCell.self, for: indexPath)
          cell.load(with: vm, delegate: self)
          return cell
        }
      } else {
        let cell = detailCollectionView.dequeue(TransactionHistoryDetailValidCell.self, for: indexPath)
        cell.load(with: vm, delegate: self)
        return cell
      }

    default:
      return UICollectionViewCell()
    }
  }

}

extension TransactionHistoryViewController: UICollectionViewDelegate {

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    switch collectionView {
    case summaryCollectionView:

      // Show detail collection view scrolled to the same indexPath as the selected summary cell
      let indexPaths = collectionView.indexPathsForVisibleItems
      detailCollectionView.reloadItems(at: indexPaths)
      detailCollectionView.scrollToItem(at: indexPath, at: .left, animated: false)
      showDetailCollectionView(true, animated: true)

    case detailCollectionView:
      collectionView.deselectItem(at: indexPath, animated: false)
    default:
      break
    }
  }
}

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
