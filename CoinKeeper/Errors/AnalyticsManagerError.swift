//
//  AnalyticsManagerError.swift
//  CoinKeeper
//
//  Created by Mitchell on 6/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum AnalyticsManagerErrorType: Error, LocalizedError {

  case submitTransactionError

  var name: String {
    switch self {
    case .submitTransactionError:
      return "Submit Transaction Error"
    }
  }
}
