//
//  XCUIElement+Swipe.swift
//  CoinKeeper
//
//  Created by Ben Winters on 10/10/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest

extension XCUIElement {
  enum Direction: Int {
    case up, down, left, right
  }

  private var half: CGFloat { return 0.5 }
  private var adjustment: CGFloat { return 0.25 }
  private var pressDuration: TimeInterval { return 0.05 }
  private var lessThanHalf: CGFloat { return half - adjustment }
  private var moreThanHalf: CGFloat { return half + adjustment }

  private var center: XCUICoordinate {
    return self.coordinate(withNormalizedOffset: CGVector(dx: half, dy: half))
  }

  private var aboveCenter: XCUICoordinate {
    return self.coordinate(withNormalizedOffset: CGVector(dx: half, dy: lessThanHalf))
  }

  private var belowCenter: XCUICoordinate {
    return self.coordinate(withNormalizedOffset: CGVector(dx: half, dy: moreThanHalf))
  }

  private var leftOfCenter: XCUICoordinate {
    return self.coordinate(withNormalizedOffset: CGVector(dx: lessThanHalf, dy: half))
  }

  private var rightOfCenter: XCUICoordinate {
    return self.coordinate(withNormalizedOffset: CGVector(dx: moreThanHalf, dy: half))
  }

  func gentleSwipe(_ direction: Direction) {
    switch direction {
    case .up:
      center.press(forDuration: pressDuration, thenDragTo: aboveCenter)
    case .down:
      center.press(forDuration: pressDuration, thenDragTo: belowCenter)
    case .left:
      center.press(forDuration: pressDuration, thenDragTo: leftOfCenter)
    case .right:
      center.press(forDuration: pressDuration, thenDragTo: rightOfCenter)
    }
  }

}
