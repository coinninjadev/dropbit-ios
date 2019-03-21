//
//  ContactCacheMigrationWorker.swift
//  DropBit
//
//  Created by Ben Winters on 3/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

class ContactCacheMigrationWorker {

  let migrators: [Migratable]

  init(migrators: [Migratable]) {
    self.migrators = migrators
  }

  func migrateIfPossible() -> Promise<Void> {
    migrators.forEach { $0.migrate() }
    return Promise.value(())
  }

}
