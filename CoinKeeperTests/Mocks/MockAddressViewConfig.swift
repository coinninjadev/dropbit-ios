//
//  MockAddressViewConfig.swift
//  DropBit
//
//  Created by Ben Winters on 9/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct MockAddressViewConfig: AddressViewConfigurable {
  let walletTxType: WalletTransactionType = .onChain
  var receiverAddress: String?
  var addressProvidedToSender: String?
  var broadcastFailed: Bool
  var invitationStatus: InvitationStatus?
}
