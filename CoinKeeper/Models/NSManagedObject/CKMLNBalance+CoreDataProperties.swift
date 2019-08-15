//
//  CKMLNBalance+CoreDataProperties.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension CKMLNBalance {

  @NSManaged public var balance: String
  @NSManaged public var pendingIn: String
  @NSManaged public var pendingOut: String
  @NSManaged public var wallet: CKMWallet?

}
