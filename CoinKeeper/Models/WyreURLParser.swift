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
  var fees: String = ""
  var amount: String = ""

  init?(url: URL) {
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let scheme = components.scheme, scheme == "dropbit",
      let host = components.host, host == "wyre",
      let queryParams = components.queryItems {

      guard queryParams.isNotEmpty else { return nil }

      var params: [String: String] = [:]
      for param in queryParams {
        params[param.name] = param.value
      }

      guard let transferID = params["transferId"],
      let orderID = params["orderId"],
      let accountID = params["accountId"],
      let destinationAddress = params["dest"],
      let fees = params["fees"],
      let amount = params["destAmount"]
        else { return nil }

      self.transferID = transferID
      self.orderID = orderID
      self.accountID = accountID
      self.destinationAddress = destinationAddress
      self.fees = fees
      self.amount = amount

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
