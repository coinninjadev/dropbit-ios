//
//  TransactionHistoryViewController+CollectionView.swift
//  DropBit
//
//  Created by Ben Winters on 8/28/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol TransactionHistorySummaryCollectionViewDelegate: AnyObject {
  func collectionViewDidProvideHitTestPoint(_ point: CGPoint, in view: UIView) -> UIView?
  func collectionViewDidCoverWalletBalance()
  func collectionViewDidUncoverWalletBalance()
}

class TransactionHistorySummaryCollectionView: UICollectionView {

  let topInset: CGFloat = 140
  let topConstraintConstant: CGFloat = 62
  weak var historyDelegate: TransactionHistorySummaryCollectionViewDelegate?

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard let hitView = super.hitTest(point, with: event) else { return nil }

    return hitView is UICollectionView ? historyDelegate?.collectionViewDidProvideHitTestPoint(point, in: hitView) : hitView
  }

}

extension TransactionHistoryViewController {

  func resetCollectionView() {
    summaryCollectionView.contentOffset = CGPoint(x: 0, y: -summaryCollectionView.topInset)
    summaryCollectionView.delegate?.scrollViewDidScroll?(summaryCollectionView)
  }

  func setupCollectionViews() {
    summaryCollectionView.registerNib(cellType: TransactionHistorySummaryCell.self)
    summaryCollectionView.showsVerticalScrollIndicator = false
    summaryCollectionView.alwaysBounceVertical = true
    summaryCollectionView.contentInset = UIEdgeInsets(top: summaryCollectionView.topInset, left: 0, bottom: 0, right: 0)

    summaryCollectionView.delegate = self
    summaryCollectionView.dataSource = self.viewModel

    summaryCollectionView.backgroundColor = .clear

    summaryCollectionView.collectionViewLayout = summaryCollectionViewLayout()

    reloadCollectionViews()

    summaryCollectionView.emptyDataSetSource = self
    summaryCollectionView.emptyDataSetDelegate = self
  }

  func reloadCollectionViews() {
    guard self.viewIfLoaded != nil else { return }
    summaryCollectionView.reloadData()
    coordinationDelegate?.viewControllerSummariesDidReload(self, indexPathsIfNotAll: nil)
  }
}

extension TransactionHistoryViewController: UICollectionViewDelegateFlowLayout {

  func summaryCollectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.scrollDirection = .vertical
    return layout
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.frame.width, height: 108)
  }

}
