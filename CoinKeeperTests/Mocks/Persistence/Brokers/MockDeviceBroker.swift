//
//  MockDeviceBroker.swift
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

class MockDeviceBroker: CKPersistenceBroker, DeviceBrokerType {

  func findOrCreateDeviceId() -> UUID {
    return UUID()
  }

  func deviceEndpointIds() -> DeviceEndpointIds? {
    return nil
  }

  func deleteDeviceEndpointIds() { }

  func setDeviceToken(string: String) { }

  var serverDeviceId: String?
  var deviceEndpointId: String?
  var pushToken: String?

}
