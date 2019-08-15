//
//  MockWalletManager.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import CNBitcoinKit
import CoreData
import PromiseKit

class MockWalletManager: WalletManager {

  var createNewWalletWithWordsWasCalled = false
  override func resetWallet(with words: [String]) {
    createNewWalletWithWordsWasCalled = true
    super.resetWallet(with: words)
  }

  var wasAskedForNewRecoveryWords = false
  var expectedWords: [String] = []
  override func mnemonicWords() -> [String] {
    wasAskedForNewRecoveryWords = true
    return expectedWords
  }

}
