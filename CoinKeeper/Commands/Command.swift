//
//  Command.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

typealias Action = () -> Void

class Command {

  private var action: Action

  init(action: @escaping Action) {
    self.action = action
  }

  func execute() {
    action()
  }
}
