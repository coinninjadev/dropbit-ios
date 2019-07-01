//
//  OperationQueueType.swift
//  DropBit
//
//  Created by BJ Miller on 12/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import os.log

protocol OperationQueueType: AnyObject {
  func addOperation(_ op: Operation)
  var maxConcurrentOperationCount: Int { get set }
  var operationCount: Int { get }
  func operations(ofType type: AsyncOperationType, ignoringAssociatedType: Bool) -> [AsynchronousOperation]
}

extension OperationQueue: OperationQueueType {
  var operationCount: Int {
    return self.operations.count
  }

  /// Returns array of AsynchronousOperation that match the supplied type and specificity
  /// If `ignoringAssociatedType == true`, results will include all operations that match the primary type.
  func operations(ofType type: AsyncOperationType, ignoringAssociatedType: Bool) -> [AsynchronousOperation] {
    let asyncOperations = self.operations.compactMap { $0 as? AsynchronousOperation }
    return asyncOperations.filter { $0.operationType.isEqual(to: type, ignoringAssociatedValues: ignoringAssociatedType) }
  }

}

public class AsynchronousOperation: Operation {

  /// State for this operation.
  @objc private enum OperationState: Int {
    case ready
    case executing
    case finished
  }

  /// Concurrent queue for synchronizing access to `state`.
  private let stateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".rw.state", attributes: .concurrent)

  private let logger = OSLog(subsystem: "com.coinninja.coinkeeper.asynchronousoperation", category: "operation")

  /// Private backing stored property for `state`.
  private var _state: OperationState = .ready

  /// The state of the operation
  @objc private dynamic var state: OperationState {
    get { return stateQueue.sync { _state } }
    set { stateQueue.sync(flags: .barrier) { _state = newValue } }
  }

  // MARK: - Various `Operation` properties

  open override var isReady: Bool { return state == .ready && super.isReady }
  public final override var isExecuting: Bool { return state == .executing }
  public final override var isFinished: Bool { return state == .finished }
  public final override var isAsynchronous: Bool { return true }

  // KVN for dependent properties

  open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
    if ["isReady", "isFinished", "isExecuting"].contains(key) {
      return [#keyPath(state)]
    }

    return super.keyPathsForValuesAffectingValue(forKey: key)
  }

  let operationType: AsyncOperationType
  init(operationType: AsyncOperationType) {
    self.operationType = operationType
    super.init()
  }

  /// The closure to be performed by this operation
  public var task: (() -> Void)?

  // Start

  var operationStartedAt: Date?

  public final override func start() {
    if isCancelled {
      finish()
      return
    }

    state = .executing

    operationStartedAt = Date()
    os_log("will begin task for operation of type: %@", log: logger, type: .debug, self.operationType.description)
    task?()
  }

  /// Call this function to finish an operation that is currently executing
  public final func finish() {
    if isExecuting {
      state = .finished

      let durationDesc = self.durationDescription() ?? ""
      os_log("did finish task for operation of type: %@, %@", log: logger, type: .debug, self.operationType.description, durationDesc)
    }
  }

  private func durationDescription() -> String? {
    guard let start = operationStartedAt else { return nil }
    let duration = Date().timeIntervalSince(start)
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 3
    guard let numberString = formatter.string(from: NSNumber(value: duration)) else { return nil }
    return "duration: \(numberString)s"
  }

}
