//
//  WalletDelegateType.swift
//  DropBit
//
//  Created by BJ Miller on 9/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol WalletDelegateType: AnyObject {
  func mainWalletManager() -> WalletManagerType?
  func resetWalletManagerIfNeeded()
}
