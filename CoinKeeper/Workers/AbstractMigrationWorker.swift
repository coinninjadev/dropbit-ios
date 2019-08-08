//
//  AbstractMigrationWorker.swift
//  DropBit
//
//  Created by BJ Miller on 3/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

class AbstractMigrationWorker {
  let migrators: [Migratable]

  init(migrators: [Migratable]) {
    self.migrators = migrators
  }

  /// Override `perform` if you need to customize the behavior of the migration
  func perform() {
    for migrator in migrators {
      if !migrator.isMigrated() {
        migrator.migrate()
        log.event("Did perform migration: \(migrator.description)")
      }
    }
  }

  func migrateIfPossible() -> Promise<Void> {
    perform()
    return Promise.value(())
  }
}
