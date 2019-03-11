//
//  SuccessFailViewModel.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/11/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct SuccessFailViewModel {
  enum Flow {
    case payment
    case restoreWallet
  }

  var flow: Flow = .payment

  var successTitle: String {
    switch flow {
    case .payment:
      return "SUCCESS"
    case .restoreWallet:
      return "WALLET RECOVERED"
    }
  }

  var successButtonTitle: String {
    switch flow {
    case .payment:
      return "OK"
    case .restoreWallet:
      return "GO TO MY WALLET"
    }
  }

  var successSubtitle: String {
    switch flow {
    case .payment:
      return ""
    case .restoreWallet:
      return "Your wallet is being imported"
    }
  }

  var failTitle: String {
    switch flow {
    case .payment, .restoreWallet:
      return "FAILED"
    }
  }

  var failSubtitle: String {
    switch flow {
    case .payment:
      return ""
    case .restoreWallet:
      return "Failed to import your wallet. \nPlease try again"
    }
  }

  var failButtonTitle: String {
    switch flow {
    case .payment, .restoreWallet:
      return "TRY AGAIN"
    }
  }
}
