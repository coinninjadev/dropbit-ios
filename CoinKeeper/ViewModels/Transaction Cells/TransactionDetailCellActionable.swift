//
//  TransactionDetailCellActionable.swift
//  DropBit
//
//  Created by Ben Winters on 10/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol TransactionDetailCellActionable {

  var bitcoinAddress: String? { get }
  var lightningInvoice: String? { get }

}
