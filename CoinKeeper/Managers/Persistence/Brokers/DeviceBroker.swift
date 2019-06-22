//
//  DeviceBroker.swift
//  DropBit
//
//  Created by Ben Winters on 6/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class DeviceBroker: CKPersistenceBroker, DeviceBrokerType {

  /// Returns either the stored UUID or the one that has just been created and stored
  @discardableResult
  func findOrCreateDeviceId() -> UUID {
    if let deviceIdString = userDefaultsManager.string(for: .uuid),
      let deviceUUID = UUID(uuidString: deviceIdString) {
      return deviceUUID
    } else {
      let newUUID = UUID()
      userDefaultsManager.set(newUUID.uuidString, for: .uuid)
      return newUUID
    }
  }

  func deviceEndpointIds() -> DeviceEndpointIds? {
    guard let deviceId = self.serverDeviceId,
      let endpointId = deviceEndpointId else {
        return nil
    }
    return DeviceEndpointIds(serverDevice: deviceId, endpoint: endpointId)
  }

  func deleteDeviceEndpointIds() {
    userDefaultsManager.removeValues(forKeys: [
      .deviceEndpointId,
      .coinNinjaServerDeviceId
      ])
  }

  func setDeviceToken(string: String) {
    userDefaultsManager.set(string, for: .devicePushToken)
  }

  var serverDeviceId: String? {
    get { return userDefaultsManager.string(for: .coinNinjaServerDeviceId) }
    set { userDefaultsManager.set(newValue, for: .coinNinjaServerDeviceId) }
  }

  var deviceEndpointId: String? {
    get { return userDefaultsManager.string(for: .deviceEndpointId) }
    set { userDefaultsManager.set(newValue, for: .deviceEndpointId) }
  }

  var pushToken: String? {
    get { return userDefaultsManager.string(for: .devicePushToken) }
    set { userDefaultsManager.set(newValue, for: .devicePushToken) }
  }

}
