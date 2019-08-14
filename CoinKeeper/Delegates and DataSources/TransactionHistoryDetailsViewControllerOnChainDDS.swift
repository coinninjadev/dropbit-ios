//
//  TransactionHistoryDetailsViewControllerOnChainDDS.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class TransactionHistoryDetailsViewControllerOnChainDDS: NSObject, UICollectionViewDelegate, UICollectionViewDataSource {

  weak var viewController: TransactionHistoryDetailsViewController?

  init(viewController: TransactionHistoryDetailsViewController) {
    self.viewController = viewController
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return viewController?.onChainFetchResultsController?.fetchedObjects?.count ?? 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let viewController = viewController,
      let viewModel = viewController.viewModelForIndexPath?(indexPath) else { return UICollectionViewCell() }

    if let invitation = viewModel.transaction?.invitation {
      switch invitation.status {
      case .canceled, .expired:
        let cell = collectionView.dequeue(TransactionHistoryDetailInvalidCell.self, for: indexPath)
        cell.load(with: viewModel, delegate: viewController)
        return cell
      default:
        let cell = collectionView.dequeue(TransactionHistoryDetailValidCell.self, for: indexPath)
        cell.load(with: viewModel, delegate: viewController)
        return cell
      }
    } else {
      let cell = collectionView.dequeue(TransactionHistoryDetailValidCell.self, for: indexPath)
      cell.load(with: viewModel, delegate: viewController)
      return cell
    }
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: false)
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    guard let viewController = viewController else { return .zero }
    let hPadding: CGFloat = 2
    let itemHeight: CGFloat = viewController.detailCollectionViewHeight
    let itemWidth: CGFloat = viewController.view.frame.width - (hPadding * 2)
    return CGSize(width: itemWidth, height: itemHeight)
  }

}
