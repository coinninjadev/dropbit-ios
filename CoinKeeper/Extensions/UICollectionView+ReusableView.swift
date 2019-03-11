//
//  UICollectionView+ReusableView.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UICollectionView {
  func registerNib<T: UICollectionViewCell>(cellType: T.Type) {
    self.register(cellType.nib(), forCellWithReuseIdentifier: cellType.reuseIdentifier)
  }

  func registerReusableView<T: UICollectionReusableView>(reusableViewType: T.Type) {
    self.register(reusableViewType.nib(),
                  forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                  withReuseIdentifier: reusableViewType.reuseIdentifier)
  }
}
