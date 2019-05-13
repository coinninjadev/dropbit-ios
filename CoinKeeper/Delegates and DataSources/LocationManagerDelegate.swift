//
//  LocationManagerDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 5/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreLocation
import os.log

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {

  let logger: OSLog = OSLog(subsystem: "com.coinninja.coinkeeper.locationManagerDelegate", category: "location_manager_delegate")

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    os_log("Location failed: %{private}@", log: logger, type: .error, error.localizedDescription)
  }
}
