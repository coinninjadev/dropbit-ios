//
//  PromiseKit+CoreData.swift
//  DropBit
//
//  Created by BJ Miller on 8/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
import CoreData

public let bgQueue = DispatchQueue.global(qos: .default)

extension Thenable {

  public func then<U>(
    on: DispatchQueue? = bgQueue,
    in context: NSManagedObjectContext,
    flags: DispatchWorkItemFlags? = nil, _
    body: @escaping (Self.T) throws -> U
    ) -> PromiseKit.Promise<U.T> where U: Thenable {

    return self.then(on: on, flags: flags, { (input: Self.T) throws -> U in
      var u: U!
      var throwable: Error?
      context.performAndWait {
        do {
          u = try body(input)
        } catch {
          throwable = error
        }
      }
      if let throwable = throwable {
        throw throwable
      } else {
        return u
      }
    })
  }

  public func get(
    on: DispatchQueue? = bgQueue,
    in context: NSManagedObjectContext,
    flags: DispatchWorkItemFlags? = nil,
    _ body: @escaping (Self.T) throws -> Swift.Void
    ) -> PromiseKit.Promise<Self.T> {

    return self.get(on: on, flags: flags, { (input: Self.T) in
      var throwable: Error?
      context.performAndWait {
        do {
          try body(input)
        } catch {
          throwable = error
        }
      }
      if let throwable = throwable {
        throw throwable
      }
    })
  }

  public func done(
    on: DispatchQueue? = bgQueue,
    in context: NSManagedObjectContext,
    flags: DispatchWorkItemFlags? = nil,
    _ body: @escaping (Self.T) throws -> Swift.Void
    ) -> PromiseKit.Promise<Swift.Void> {
    return self.done(on: on, flags: flags, { (input) in
      var throwable: Error?
      context.performAndWait {
        do {
          try body(input)
        } catch {
          throwable = error
        }
      }
      if let throwable = throwable {
        throw throwable
      }
    })
  }

  public func compactMap<U>(
    on: DispatchQueue? = bgQueue,
    in context: NSManagedObjectContext,
    flags: DispatchWorkItemFlags? = nil,
    _ transform: @escaping (Self.T) throws -> U?
    ) -> PromiseKit.Promise<U> {
    return self.compactMap(on: on, flags: flags, { (input) -> U? in
      var u: U?
      var throwable: Error?
      context.performAndWait {
        do {
          u = try transform(input)
        } catch {
          throwable = error
        }
      }
      if let throwable = throwable {
        throw throwable
      } else {
        return u
      }
    })
  }
}

extension CatchMixin {

  public func `catch`(
    on: DispatchQueue? = bgQueue,
    in context: NSManagedObjectContext,
    policy: CatchPolicy = .allErrors,
    flags: DispatchWorkItemFlags? = nil,
    body: @escaping (Error) -> Void
    ) -> PMKFinalizer {

    return self.catch(on: on, flags: flags, policy: policy, { error in
      context.performAndWait {
        body(error)
      }
    })
  }
}
