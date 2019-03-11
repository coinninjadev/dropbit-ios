//
//  CoreDataStackConfig.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

struct CoreDataStackConfig {
  let stackType: CoreDataStackType
  let storeType: CoreDataStoreType

  enum CoreDataStoreType {
    case disk, inMemory

    var storeType: String {
      switch self {
      case .disk: return NSSQLiteStoreType
      case .inMemory: return NSInMemoryStoreType
      }
    }
  }

  enum CoreDataStackType {
    case main, contactCache

    var modelName: String {
      switch self {
      case .main: return "Model"
      case .contactCache: return "ContactCache"
      }
    }

    var containerName: String {
      switch self {
      case .main: return "CoinKeeper"
      case .contactCache: return "ContactCacheDB"
      }
    }
  }
}
