//
//  LocationManagerDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 5/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreLocation

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    log.errorPrivate(error.localizedDescription)
  }
}
