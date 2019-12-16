//
//  NSManagedObject+Init.swift
//  DropBit
//
//  Created by BJ Miller on 4/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData

extension NSManagedObject {

  static func entityName() -> String {
    return String(describing: self)
  }

  static func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
    return NSEntityDescription.entity(forEntityName: entityName(), in: context)!
  }

  public convenience init(insertInto context: NSManagedObjectContext) {
    self.init(entity: type(of: self).entityDescription(in: context), insertInto: context)
  }

}
