//
//  OutgoingInvitationDTO.swift
//  DropBit
//
//  Created by BJ Miller on 12/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct OutgoingInvitationDTO {
  let contact: ContactType
  let btcPair: BitcoinUSDPair
  let fee: Int // in satoshis
  let sharedPayloadDTO: SharedPayloadDTO?
}
