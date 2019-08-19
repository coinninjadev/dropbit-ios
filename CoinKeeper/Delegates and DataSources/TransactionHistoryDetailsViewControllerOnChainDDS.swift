//
//  TransactionHistoryDetailsViewControllerOnChainDDS.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

//swiftlint:disable type_name
class TransactionHistoryDetailsViewControllerOnChainDDS: TransactionHistoryDetailsViewControllerDDS,
UICollectionViewDelegate, UICollectionViewDataSource {

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return viewController?.onChainFetchResultsController?.fetchedObjects?.count ?? 0
  }

}
