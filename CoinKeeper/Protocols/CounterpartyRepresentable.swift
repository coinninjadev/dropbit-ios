//
//  CounterpartyRepresentable.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol CounterpartyRepresentable: AnyObject {

  var isIncoming: Bool { get }
  var counterpartyName: String? { get }
  var counterpartyAddressId: String? { get }

  func counterpartyDisplayIdentity(deviceCountryCode: Int?) -> String?

}

extension CounterpartyRepresentable {

  func counterpartyDisplayDescription(deviceCountryCode: Int?) -> String? {
    if let name = counterpartyName {
      return name
    } else if let identity = counterpartyDisplayIdentity(deviceCountryCode: deviceCountryCode) {
      return identity
    } else {
      return counterpartyAddressId
    }
  }

}
