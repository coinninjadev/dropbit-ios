//
//  CKMLNAccount+CoreDataProperties.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension CKMLNAccount {

  @NSManaged public var id: String
  @NSManaged public var balance: Int
  @NSManaged public var pendingIn: Int
  @NSManaged public var pendingOut: Int
  @NSManaged public var address: String
  @NSManaged public var wallet: CKMWallet

}
