//
//  SQLiteCoreDataStack.swift
//  DropBit
//
//  Created by BJ Miller on 3/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData
import os.log

class SQLiteCoreDataStack: BaseCoreDataStack {

  override init(stackConfig: CoreDataStackConfig = CoreDataStackConfig(stackType: .main, storeType: .disk)) {
    super.init(stackConfig: stackConfig)
  }

  override func createPersistentContainer() -> NSPersistentContainer {
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.sqlitecoredatastack", category: "create_persistent_container")
    let container = NSPersistentContainer(name: stackConfig.stackType.containerName, managedObjectModel: managedObjectModel)
    let directory = NSPersistentContainer.defaultDirectoryURL()
    let storeURL = directory.appendingPathComponent("\(stackConfig.stackType.containerName).sqlite")
    let description = NSPersistentStoreDescription(url: storeURL)
    description.shouldInferMappingModelAutomatically = true
    description.shouldMigrateStoreAutomatically = true
    description.setOption(FileProtectionType.completeUntilFirstUserAuthentication as NSObject, forKey: NSPersistentStoreFileProtectionKey)
    description.type = stackConfig.storeType.storeType
    description.shouldAddStoreAsynchronously = stackConfig.storeType.shouldAddStoreAsynchronously
    container.persistentStoreDescriptions = [description]

    container.loadPersistentStores { (_, error) in
      if let err = error {
        os_log("Failed to load persistence stores: %@", log: logger, type: .error, err.localizedDescription)
      }
      self.stackConfig.stackType.postInitHandler(for: container)
    }
    return container
  }
}
