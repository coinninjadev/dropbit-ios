//
//  DeviceCountryCodeProvider.swift
//  DropBit
//
//  Created by Ben Winters on 2/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol DeviceCountryCodeProvider: AnyObject {
  func deviceCountryCode() -> Int?
}
