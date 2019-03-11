//
//  NSManagedObjectContext+PerformRethrow.swift
//  DropBit
//
//  Created by Ben Winters on 2/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {

  /// Makes it much easier to call performAndWait within a promise or other throwing function
  func performThrowingAndWait<T>(_ block: () throws -> T) rethrows -> T {
    return try _performAndWaitHelper(
      fn: performAndWait, execute: block, rescue: { throw $0 }
    )
  }

  private func _performAndWaitHelper<T>(fn: (() -> Void) -> Void,
                                        execute work: () throws -> T,
                                        rescue: ((Error) throws -> (T))) rethrows -> T {
    var result: T?
    var error: Error?
    withoutActuallyEscaping(work) { _work in
      fn {
        do {
          result = try _work()
        } catch let e {
          error = e
        }
      }
    }
    if let e = error {
      return try rescue(e)
    } else {
      return result!
    }
  }
}
