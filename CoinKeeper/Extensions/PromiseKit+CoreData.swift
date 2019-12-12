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

public func performIn<U>(_ context: NSManagedObjectContext, body: @escaping () throws -> U) -> Promise<U> {
  return Promise { seal in
    context.perform {
      do {
        let val = try body()
        seal.fulfill(val)
      } catch {
        seal.reject(error)
      }
    }
  }
}

extension Thenable {

  public func then<U>(
    in context: NSManagedObjectContext,
    _ body: @escaping (Self.T) throws -> U
    ) -> PromiseKit.Promise<U.T> where U: Thenable {

    return Promise { seal in
      pipe { value in
        switch value {
        case .fulfilled(let val):
          context.perform {
            do {
              let ret = try body(val)
              ret.pipe { (result) in
                seal.resolve(result)
              }
            } catch {
              seal.reject(error)
            }
          }
        case .rejected(let err):
          seal.reject(err)
        }
      }
    }
  }

  public func get(
    in context: NSManagedObjectContext,
    _ body: @escaping (Self.T) throws -> Swift.Void
    ) -> PromiseKit.Promise<Self.T> {

    return Promise { seal in
      pipe { value in
        switch value {
        case .fulfilled(let val):
          context.perform {
            do {
              try body(val)
              seal.fulfill(val)
            } catch {
              seal.reject(error)
            }
          }
        case .rejected(let err):
          seal.reject(err)
        }
      }
    }
  }

  public func done(
    in context: NSManagedObjectContext,
    _ body: @escaping (Self.T) throws -> Swift.Void
    ) -> PromiseKit.Promise<Swift.Void> {

    return Promise { seal in
      pipe { value in
        switch value {
        case .fulfilled(let val):
          context.perform {
            do {
              try body(val)
              seal.fulfill(())
            } catch {
              seal.reject(error)
            }
          }
        case .rejected(let err):
          seal.reject(err)
        }
      }
    }
  }
}
