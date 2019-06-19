//
//  MockCheckInBroker.swift
//  DropBitTests
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import Foundation
import PromiseKit
@testable import DropBit

class MockCheckInBroker: CKPersistenceBroker, CheckInBrokerType {

  var cachedBTCUSDRate: Double = 0

  var cachedBlockheight: Int = 0

  var cachedBestFee: Double = 0

  var cachedBetterFee: Double = 0

  var cachedGoodFee: Double = 0

}
