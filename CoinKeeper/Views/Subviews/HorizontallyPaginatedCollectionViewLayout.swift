//
//  HorizontallyPaginatedCollectionViewLayout.swift
//  DropBit
//
//  Created by BJ Miller on 6/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

/// Used for horizontal scrolling cells while maintaining centering and showing previous/next cells on either side
class HorizontallyPaginatedCollectionViewLayout: UICollectionViewFlowLayout {

  override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
    guard let collectionView = collectionView else { return proposedContentOffset }

    let currentXOffset = collectionView.contentOffset.x
    let nextXOffset = proposedContentOffset.x

    let maxIndex = ceil(currentXOffset / pageWidth)
    let minIndex = floor(currentXOffset / pageWidth)

    // Number of pages for offset
    var index: CGFloat = 0

    if nextXOffset > currentXOffset {
      index = maxIndex
    } else {
      index = minIndex
    }

    // offset is total page width, reduced by by the left inset to keep the cell centered, (will bounce back if negative)
    let xOffset = (pageWidth * index) - collectionView.contentInset.left
    let point = CGPoint(x: xOffset, y: 0)

    return point
  }

  var pageWidth: CGFloat {
    return itemSize.width + minimumLineSpacing
  }
}
