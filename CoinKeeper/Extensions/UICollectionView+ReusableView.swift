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

  func dequeue<T: UICollectionViewCell>(_: T.Type, for indexPath: IndexPath) -> T {
    guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
      fatalError("Could not dequeue cell with type \(T.reuseIdentifier)")
    }
    return cell
  }
}
