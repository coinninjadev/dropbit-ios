//
//  DefaultHeaders.swift
//  DropBit
//
//  Created by BJ Miller on 10/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct DefaultHeaders {
  var timeStamp: String
  var devicePlatform: String
  var appVersion: String
  var signature: String?
  var walletId: String?
  var userId: String?
  var deviceId: UUID?
  var pubKeyString: String?
  var udid: String
  var buildEnvironment: ApplicationBuildEnvironment
}
