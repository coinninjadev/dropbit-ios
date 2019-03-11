//
//  CounterpartyRepresentable.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit

protocol CounterpartyRepresentable: AnyObject {

  var isIncoming: Bool { get }
  var counterpartyName: String? { get }
  var counterpartyAddressId: String? { get }

  func counterpartyPhoneNumber(deviceCountryCode: Int?, kit: PhoneNumberKit) -> String?

}

extension CounterpartyRepresentable {

  func counterpartyDisplayDescription(deviceCountryCode: Int?, kit: PhoneNumberKit) -> String? {
    if let name = counterpartyName {
      return name
    } else if let number = counterpartyPhoneNumber(deviceCountryCode: deviceCountryCode, kit: kit) {
      return number
    } else {
      return counterpartyAddressId
    }
  }

}
