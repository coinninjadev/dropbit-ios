//
//  CKMServerAddress+CoreDataProperties.swift
//  CoinKeeper
//
//  Created by Ben Winters on 5/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMServerAddress {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMServerAddress> {
    return NSFetchRequest<CKMServerAddress>(entityName: "CKMServerAddress")
  }

  @NSManaged public var address: String

  /// Set by the API response created_at date, not when the managed object was created locally
  @NSManaged public var createdAt: Date

  @NSManaged public var derivativePath: CKMDerivativePath?
  @NSManaged public var wallet: CKMWallet?

}
