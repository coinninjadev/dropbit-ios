//
//  Sequence+Shuffled.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

//import Foundation

import CommonCrypto

extension MutableCollection {
  /// Shuffles the contents of this collection
  mutating func shuffle() {
    let initialCount = count
    guard initialCount > 1 else { return }

    for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: initialCount, to: 1, by: -1)) {
      let distance: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
      let idx = index(firstUnshuffled, offsetBy: distance)
      swapAt(firstUnshuffled, idx)
    }
  }
}

extension Sequence {
  /// Returns an array with the contents of this sequence shuffled
  func shuffled() -> [Element] {
    var result = Array(self)
    result.shuffle()
    return result
  }
}
