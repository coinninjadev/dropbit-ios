//
//  WyreURLParser.swift
//  DropBit
//
//  Created by BJ Miller on 10/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class WyreURLParser {

  var transferID: String = ""
  var orderID: String = ""
  var accountID: String = ""
  var destinationAddress: String = ""
  var fees: Double = 0.0
  var amount: Double = 0.0

  init?(url: URL) {
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let scheme = components.scheme, scheme == "dropbit",
      let host = components.host, host == "wyre",
      let queryParams = components.queryItems {

      for param in queryParams {
        if param.name == "transferId", let value = param.value {
          self.transferID = value
        } else if param.name == "orderId", let value = param.value {
          self.orderID = value
        } else if param.name == "accountId", let value = param.value {
          self.accountID = value
        } else if param.name == "dest", let value = param.value {
          self.destinationAddress = value
        } else if param.name == "fees", let value = param.value {
          self.fees = Double(value) ?? 0.0
        } else if param.name == "destAmount", let value = param.value {
          self.amount = Double(value) ?? 0.0
        } else {
          return nil
        }
      }
    } else {
      return nil
    }
  }

  var humanReadableDescription: String {
    return "Your Bitcoin purchase is processing. Here is your information:\n\n" +
    "Transfer ID: \(transferID)\n" +
    "Order ID: \(orderID)" +
    "Address: \(destinationAddress)" +
    "Amount: \(amount)" +
    "Fees: \(fees)"
  }
}
