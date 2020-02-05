//
//  LaunchURLType.swift
//  DropBit
//
//  Created by Mitchell Malleo on 1/23/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Firebase

enum LaunchURLType {
  case standard
  case widget
  case dynamicLink(DynamicLink?)
  case bitcoin(BitcoinURL)
  case wyre(WyreURLParser)
}
