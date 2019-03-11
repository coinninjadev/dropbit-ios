//
//  NSManagedObjectContext+Changes.swift
//  CoinKeeper
//
//  Created by Ben Winters on 6/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {

  func insertedObjects<T: NSManagedObject>(ofType type: T.Type) -> Set<T> {
    let typeName = String(describing: type)
    let inserted = self.insertedObjects.filter { $0.entity.name == typeName }
    let insertedOfType: [T] = inserted.compactMap { $0 as? T }
    return Set(insertedOfType)
  }

}
