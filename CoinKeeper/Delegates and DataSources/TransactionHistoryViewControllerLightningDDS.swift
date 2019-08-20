//
//  TransactionHistoryViewControllerLightningDDS.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class TransactionHistoryViewControllerLightningDDS: TransactionHistoryViewControllerDDS,
  UICollectionViewDataSource,
  UICollectionViewDelegateFlowLayout {

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    guard let viewController = viewController else { return 0 }
    return viewController.lightningFetchResultsController.sections?.count ?? 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    guard let viewController = viewController, let sections = viewController.lightningFetchResultsController.sections else { return 0 }
    let numberOfObjects = sections[section].numberOfObjects
    return numberOfObjects
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let viewController = viewController else { return UICollectionViewCell() }
    let cell = collectionView.dequeue(TransactionHistorySummaryCell.self, for: indexPath)
    let invoice = viewController.lightningFetchResultsController.object(at: indexPath)
    let viewModel = viewController.summaryViewModel(for: invoice)
    cell.load(with: viewModel, isAtTop: indexPath.row == 0 && indexPath.section == 0)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    guard let viewController = viewController else { return .zero }
    let invoice = viewController.lightningFetchResultsController.object(at: indexPath)
    var height: CGFloat = 66
    //height += (transaction.memo?.asNilIfEmpty() != nil) ? 25 : 0 TODO
    return CGSize(width: collectionView.frame.width, height: height)
  }

}
