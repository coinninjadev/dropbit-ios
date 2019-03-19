//
//  InMemoryPersistentContainer.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData

class InMemoryCoreDataStack: BaseCoreDataStack {

  override init(stackConfig: CoreDataStackConfig = CoreDataStackConfig(stackType: .main, storeType: .inMemory)) {
    super.init(stackConfig: stackConfig)
  }

  override func createPersistentContainer() -> NSPersistentContainer {
    let container = NSPersistentContainer(name: stackConfig.stackType.containerName, managedObjectModel: managedObjectModel)
    let description = NSPersistentStoreDescription()
    description.type = stackConfig.storeType.storeType

    container.persistentStoreDescriptions = [description]
    container.loadPersistentStores { (description, error) in
      // Check if the data store is in memory
      precondition( description.type == NSInMemoryStoreType )

      // Check that container was created correctly
      if let error = error {
        fatalError("Failed to create in-memory store \(error)")
      }
    }
    return container
  }
}
