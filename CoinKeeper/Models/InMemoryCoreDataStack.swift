//
//  InMemoryPersistentContainer.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData

class InMemoryCoreDataStack {

  lazy var managedObjectModel: NSManagedObjectModel = {
    let url = Bundle.main.url(forResource: "Model", withExtension: "momd")!
    let model = NSManagedObjectModel(contentsOf: url)!
    return model
  }()

  lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "CoinKeeper", managedObjectModel: managedObjectModel)
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    description.shouldAddStoreAsynchronously = false // Make it simpler in test env

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
  }()

  var context: NSManagedObjectContext {
    return persistentContainer.viewContext
  }

}
