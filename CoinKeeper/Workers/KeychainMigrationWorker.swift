//
//  KeychainMigrationWorker.swift
//  DropBit
//
//  Created by Ben Winters on 1/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

enum KeychainMigrationVersion: String {
  case v1tov2 // update accessibility setting for stored values
}

class KeychainMigrationWorker: AbstractMigrationWorker { }
