//
//  PendingInvitationError.swift
//  DropBit
//
//  Created by BJ Miller on 7/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

enum PendingInvitationError: Error {
  case noPendingInvitationExistsForID
  case noSentInvitationExistsForID
  case noAddressProvided
  case noInvoiceProvided
  case insufficientFundsForInvitationWithID(String)
  case insufficientFeeForInvitationWithID(String)
}
