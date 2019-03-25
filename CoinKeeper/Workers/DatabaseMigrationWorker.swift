//
//  DatabaseMigrationWorker.swift
//  DropBit
//
//  Created by BJ Miller on 12/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit

protocol Migratable {
  func migrate()
}

enum DatabaseMigrationVersion: String {
  case v1tov2
  case v4Grooming
}

class DatabaseMigrationWorker {

  let migrators: [Migratable]

  init(migrators: [Migratable]) {
    self.migrators = migrators
  }

  func migrateIfPossible(in context: NSManagedObjectContext) -> Promise<Void> {
    context.performAndWait {
      migrators.forEach { $0.migrate() }
    }
    return Promise.value(())
  }

}
