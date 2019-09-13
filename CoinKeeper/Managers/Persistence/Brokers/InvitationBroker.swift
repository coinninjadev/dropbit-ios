//
//  InvitationBroker.swift
//  DropBit
//
//  Created by Ben Winters on 6/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData

class InvitationBroker: CKPersistenceBroker, InvitationBrokerType {

  func getUnacknowledgedInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
    return databaseManager.getUnacknowledgedInvitations(in: context)
  }

  func getAllInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
    return databaseManager.getAllInvitations(in: context)
  }

  func persistUnacknowledgedInvitation(withDTO outgoingDTO: OutgoingInvitationDTO,
                                       acknowledgmentId: String,
                                       in context: NSManagedObjectContext) {
    _ = CKMInvitation(withOutgoingInvitationDTO: outgoingDTO,
                      acknowledgmentId: acknowledgmentId,
                      insertInto: context)
  }

  func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String] {
    return databaseManager.addressesProvidedForReceivedPendingDropBits(in: context)
  }

  func acknowledgeInvitation(with outgoingTransactionData: OutgoingTransactionData,
                             response: WalletAddressRequestResponse,
                             in context: NSManagedObjectContext) {
    guard let invitation = CKMInvitation.updateIfExists(withAddressRequestResponse: response,
                                                        side: .sent, isAcknowledged: false, in: context) else { return }
    let transaction = CKMTransaction.findOrCreate(with: outgoingTransactionData, in: context)
    if let sharedPayload = outgoingTransactionData.sharedPayloadDTO {
      transaction.configureNewSenderSharedPayload(with: sharedPayload, in: context)
    }

    invitation.transaction = transaction
    invitation.counterpartyTwitterContact = transaction.twitterContact
    invitation.counterpartyPhoneNumber = transaction.phoneNumber
  }

}
