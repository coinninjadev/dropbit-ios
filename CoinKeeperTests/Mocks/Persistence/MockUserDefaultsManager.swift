//
//  MockUserDefaultsManager.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/7/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockUserDefaultsManager: PersistenceUserDefaultsType {

  let standardDefaults: UserDefaults = UserDefaults(suiteName: "com.coinninja.unittests")!
  let configDefaults: UserDefaults = UserDefaults(suiteName: "com.coinninja.unittests.config")!

  var useRegtest: Bool = false

  func deleteAll() {}
  func deleteWallet() {}
  func unverifyUser() {}

}
