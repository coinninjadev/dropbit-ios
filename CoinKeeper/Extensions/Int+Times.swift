//
// Created by BJ Miller on 2/15/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension Int {
  func times(_ function: () -> Void) {
    (0..<self).forEach { _ in
      function()
    }
  }
}
