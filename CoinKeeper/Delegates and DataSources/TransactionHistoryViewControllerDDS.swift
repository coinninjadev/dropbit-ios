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
