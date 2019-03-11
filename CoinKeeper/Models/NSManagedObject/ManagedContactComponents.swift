//
//  ManagedContactComponents.swift
//  DropBit
//
//  Created by BJ Miller on 3/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct ManagedCounterpartyInputs {
  let name: String
}

public struct ManagedContactComponents {
  let counterpartyInputs: ManagedCounterpartyInputs
  let phonenumberInputs: ManagedPhoneNumberInputs
}
