//
//  MockWalletDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 9/17/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockWalletDelegate: WalletDelegateType {

  let mockWalletManager = MockWalletManager(words: WalletManager.createMnemonicWords())
  func mainWalletManager() -> WalletManagerType? {
    return mockWalletManager
  }

}
