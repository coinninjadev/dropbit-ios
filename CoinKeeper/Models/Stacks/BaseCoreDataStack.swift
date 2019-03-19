//
//  BaseCoreDataStack.swift
//  DropBit
//
//  Created by BJ Miller on 3/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

class BaseCoreDataStack {

  let stackConfig: CoreDataStackConfig

  init(stackConfig: CoreDataStackConfig) {
    self.stackConfig = stackConfig
    _ = persistentContainer // lazy load
  }

  lazy var managedObjectModel: NSManagedObjectModel = {
    let model = Bundle.main
      .url(forResource: stackConfig.stackType.modelName, withExtension: "momd")
      .flatMap { NSManagedObjectModel(contentsOf: $0) }
    return model!
  }()

  lazy var persistentContainer: NSPersistentContainer = {
    return createPersistentContainer()
  }()

  /// Do not call createPersistentContainer directly;
  ///  it is only meant to be overridden in subclass and vended by `lazy var persistentContainer`.
  func createPersistentContainer() -> NSPersistentContainer {
    fatalError("subclass must override")
  }

  var context: NSManagedObjectContext {
    return persistentContainer.viewContext
  }
}
