//
//  TransactionHistoryViewControllerDDS.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/16/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class TransactionHistoryViewControllerDDS: NSObject, UICollectionViewDelegate {

  weak var viewController: TransactionHistoryViewController?

  init(viewController: TransactionHistoryViewController) {
    self.viewController = viewController
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let viewController = viewController else { return }
    viewController.showDetailCollectionView(true, indexPath: indexPath, animated: true)
  }
}

extension TransactionHistoryViewControllerDDS: UIScrollViewDelegate {

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let topOfWalletBalanceOffset: CGFloat = -60, middleOfWalletBalanceOffset: CGFloat = -100
    let collectionViewFullScreenOffset = scrollView.contentOffset.y < middleOfWalletBalanceOffset
    let collectionViewPartialScreenOffset = scrollView.contentOffset.y > topOfWalletBalanceOffset
    guard let viewController = viewController, collectionViewFullScreenOffset || collectionViewPartialScreenOffset else { return }

    if collectionViewPartialScreenOffset {
      viewController.summaryCollectionView.historyDelegate?.collectionViewDidCoverWalletBalance()
      viewController.isCollectionViewFullScreen = false
    } else {
      viewController.summaryCollectionView.historyDelegate?.collectionViewDidUncoverWalletBalance()
      viewController.isCollectionViewFullScreen = true
    }

    let offset = abs(scrollView.contentOffset.y)
    viewController.refreshViewTopConstraint.constant = offset - viewController.refreshView.frame.size.height
    viewController.refreshView.animateLogo(to: scrollView.contentOffset.y)
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    guard let viewController = viewController else { return }
    viewController.refreshView.reset()
    viewController.refreshViewTopConstraint.constant = 0
  }

  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    guard let viewController = viewController else { return }
    viewController.refreshView.fireRefreshAnimationIfNecessary()

    if viewController.refreshView.shouldQueueRefresh {
      viewController.coordinationDelegate?.viewControllerAttemptedToRefreshTransactions(viewController)
    }
  }
}
