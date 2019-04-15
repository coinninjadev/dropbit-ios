//
//  PendingInvitationData.swift
//  CoinKeeper
//
//  Created by BJ Miller on 7/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit

struct PendingInvitationData: Codable {
  let id: String     // invitation id
  let btcAmount: Int // in satoshis
  let fiatAmount: Int
  let feeAmount: Int // in satoshis
  let name: String?
  let phoneNumber: GlobalPhoneNumber?
  var address: String?
  var addressPubKey: String?
  var userNotified = false
  var failedToSendAt: Date?
  var memo: String?
}

extension PendingInvitationData {
  func asData() -> Data? {
    return try? JSONEncoder().encode(self)
  }

  static func decode(from data: Data) -> PendingInvitationData? {
    return try? JSONDecoder().decode(PendingInvitationData.self, from: data)
  }

  /// Initializer from WalletAddressRequestResponse object.
  ///  Meant to be invoked on the sender side, when the receiver has fulfilled an address request.
  ///
  /// - Parameter walletAddressRequestResponse: a WalletAddressRequestResponse object.
  init(walletAddressRequestResponse response: WalletAddressRequestResponse, kit: PhoneNumberKit) {
    self.init(
      id: response.id,
      btcAmount: response.metadata?.amount?.btc ?? 0,
      fiatAmount: response.metadata?.amount?.usd ?? 0,
      feeAmount: 0, // not incluced in WARR object
      name: nil,
      phoneNumber: response.metadata?.sender.flatMap { GlobalPhoneNumber(participant: $0, kit: kit) },
      address: response.address,
      addressPubKey: response.addressPubkey,
      userNotified: false,
      failedToSendAt: nil,
      memo: nil
    )
  }

}
