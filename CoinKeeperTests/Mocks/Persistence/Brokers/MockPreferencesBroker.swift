//
//  MockPreferencesBroker.swift
//  DropBitTests
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import Foundation
import PromiseKit
@testable import DropBit

class MockPreferencesBroker: CKPersistenceBroker, PreferencesBrokerType {

  var dustProtectionMinimumAmount: Int = 0
  var dustProtectionIsEnabled: Bool = false
  var yearlyPriceHighNotificationIsEnabled: Bool = false
  var selectedCurrency: SelectedCurrency = .BTC
  var dontShowShareTransaction: Bool = false
  var dontShowLightningRefill: Bool = false
  var didOptOutOfInvitationPopup: Bool = false
  var adjustableFeesIsEnabled: Bool = false
  var preferredTransactionFeeType: TransactionFeeType = .default
  var selectedWalletTransactionType: WalletTransactionType = .onChain
  var lightningWalletLockedStatus: LockStatus = .locked

}
