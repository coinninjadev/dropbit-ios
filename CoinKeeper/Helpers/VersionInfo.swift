//
//  Global.swift
//  DropBit
//
//  Created by Mitch on 9/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

struct VersionInfo {

  let iosVersion: String
  let appVersion: String
  let appBuild: String

  init() {
    iosVersion = UIDevice.current.systemVersion
    appVersion = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "Unknown")"
    appBuild = "\(Bundle.main.infoDictionary?["CFBundleVersion"] ?? "Unknown")"
  }

  var debugDescription: String {
    return "DropBit: \(appVersion) (\(appBuild)), iOS: \(iosVersion)"
  }
}
