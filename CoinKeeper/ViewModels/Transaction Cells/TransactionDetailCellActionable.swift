//
//  TransactionDetailCellActionable.swift
//  DropBit
//
//  Created by Ben Winters on 10/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// An object that can be shared or mutated based on actions taken by the user in the transaction detail cell
protocol TransactionDetailCellActionable {

  var bitcoinAddress: String? { get }
  var lightningInvoice: String? { get }
  var memo: String? { get }

}
