//
//  BalanceUpdateable.swift
//  CoinKeeper
//
//  Created by Ben Winters on 5/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol BalanceUpdateable: AnyObject {

  /// Holds token for observing .didUpdateBalance
  var balanceNotificationToken: NotificationToken? { get set }

  func updateViewWithBalance()

}

extension BalanceUpdateable {

  func subscribeToBalanceUpdates() {
    balanceNotificationToken = CKNotificationCenter.subscribe(key: .didUpdateBalance, object: nil, queue: nil, using: { [weak self] _ in
      self?.updateViewWithBalance()
    })
  }

}
