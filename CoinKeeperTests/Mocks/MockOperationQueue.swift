//
//  MockOperationQueue.swift
//  DropBit
//
//  Created by BJ Miller on 12/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockOperationQueue: OperationQueueType {
  var addOperationWasCalled = false
  var operations: [Operation] = []
  func addOperation(_ op: Operation) {
    addOperationWasCalled = true
    operations.append(op)
    op.start()
  }

  var maxConcurrentOperationCountValue = 1
  var maxConcurrentOperationCount: Int {
    get {
      return maxConcurrentOperationCountValue
    }
    set {
      maxConcurrentOperationCountValue = newValue
    }
  }

  var operationCount: Int {
    return operations.count
  }

  func operations(ofType type: AsyncOperationType, ignoringAssociatedType: Bool) -> [AsynchronousOperation] {
    return []
  }

}
