//
//  PinEntryViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 8/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class PinEntryViewModel {
  let shouldEnableBiometrics: Bool
  let shouldShowLogo: Bool
  let shouldShowCloseButton: Bool
  let message: String?

  var shouldAnimatePinText = false

  init(enableBiometrics: Bool,
       showLogo: Bool,
       showClose: Bool,
       message: String?) {
    self.shouldEnableBiometrics = enableBiometrics
    self.shouldShowLogo = showLogo
    self.shouldShowCloseButton = showClose
    self.message = message
  }

  static var confirmTransactionMessage: String {
    return "Enter PIN to confirm transaction"
  }
}

/// Previously .standard mode
class OpenAppPinEntryViewModel: PinEntryViewModel {
  init() {
    super.init(enableBiometrics: true,
               showLogo: true,
               showClose: false,
               message: nil)
  }
}

class InviteVerificationPinEntryViewModel: PinEntryViewModel {
  init() {
    super.init(enableBiometrics: true,
               showLogo: false,
               showClose: true,
               message: PinEntryViewModel.confirmTransactionMessage)
  }
}

class PaymentVerificationPinEntryViewModel: PinEntryViewModel {
  init(amountDisablesBiometrics: Bool) {
    super.init(enableBiometrics: !amountDisablesBiometrics,
               showLogo: false,
               showClose: true,
               message: PinEntryViewModel.confirmTransactionMessage)
  }
}

class WalletDeletionPinEntryViewModel: PinEntryViewModel {
  init() {
    super.init(enableBiometrics: false,
               showLogo: true,
               showClose: true,
               message: "Enter PIN to confirm deletion of your wallet")
    self.shouldAnimatePinText = true
  }
}

class RecoveryWordsPinEntryViewModel: PinEntryViewModel {
  init() {
    super.init(enableBiometrics: false,
               showLogo: true,
               showClose: true,
               message: "Enter PIN to unlock recovery words")
  }
}
