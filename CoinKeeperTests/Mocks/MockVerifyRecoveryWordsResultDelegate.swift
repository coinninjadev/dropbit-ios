//
//  MockVerifyRecoveryWordsResultDelegate.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit

class MockVerifyRecoveryWordsResultDelegate: VerifyRecoveryWordsResultDelegate {
  var firstMatchFoundWasCalled = false
  func firstMatchFound() {
    firstMatchFoundWasCalled = true
  }

  var secondMatchFoundWasCalled = false
  func secondMatchFound() {
    secondMatchFoundWasCalled = true
  }

  var errorFoundWasCalled = false
  func errorFound() {
    errorFoundWasCalled = true
  }

  var fatalErrorFoundWasCalled = false
  func fatalErrorFound() {
    fatalErrorFoundWasCalled = true
  }
}
