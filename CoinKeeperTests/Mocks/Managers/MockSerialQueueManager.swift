//
//  MockSyncManager.swift
//  DropBit
//
//  Created by Mitch on 1/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
@testable import DropBit

class MockSerialQueueManager: SerialQueueManagerType {
  var queue: OperationQueueType = OperationQueue()

  var timer: Timer = Timer()

  weak var delegate: SerialQueueManagerDelegate?

  var enqueueWalletSyncIfAppropriateWasCalled: Bool = false
  func enqueueWalletSyncIfAppropriate(type: WalletSyncType,
                                      policy: EnqueueingPolicy,
                                      completion: CKErrorCompletion?,
                                      fetchResult: ((UIBackgroundFetchResult) -> Void)?) {
    enqueueWalletSyncIfAppropriateWasCalled = true
    completion?(nil)
  }

  func enqueueOperationIfAppropriate(_ operation: AsynchronousOperation, policy: EnqueueingPolicy) { }
  func enqueueOptionalIncrementalSync() { }

}
