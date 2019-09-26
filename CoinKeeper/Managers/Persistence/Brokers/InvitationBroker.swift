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

  func persistUnacknowledgedInvitation(withDTO invitationDTO: OutgoingInvitationDTO,
                                       acknowledgmentId: String,
                                       in context: NSManagedObjectContext) {
    _ = CKMInvitation(withOutgoingInvitationDTO: invitationDTO,
                      acknowledgmentId: acknowledgmentId,
                      insertInto: context)
  }

  func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String] {
    return databaseManager.addressesProvidedForReceivedPendingDropBits(in: context)
  }

  func acknowledgeInvitation(with outgoingTransactionData: OutgoingTransactionData,
                             response: WalletAddressRequestResponse,
                             in context: NSManagedObjectContext) {
    guard let pendingInvitation = CKMInvitation.updateIfExists(withAddressRequestResponse: response,
                                                               side: .sent, isAcknowledged: false, in: context),
      let parentObject = invitationParentObject(for: outgoingTransactionData,
                                                walletTxType: pendingInvitation.walletTxTypeCase,
                                                in: context) else { return }

    if let sharedPayload = outgoingTransactionData.sharedPayloadDTO {
      parentObject.configureNewSenderSharedPayload(with: sharedPayload, in: context)
    }

    parentObject.invitation = pendingInvitation
    parentObject.twitterContact = pendingInvitation.counterpartyTwitterContact
    parentObject.phoneNumber = pendingInvitation.counterpartyPhoneNumber
  }

  func invitationParentObject(for outgoingTransactionData: OutgoingTransactionData,
                              walletTxType: WalletTransactionType,
                              in context: NSManagedObjectContext) -> InvitationParent? {
    switch walletTxType {
    case .onChain:
      return CKMTransaction.findOrCreate(with: outgoingTransactionData, in: context)
    case .lightning:
      guard let wallet = CKMWallet.find(in: context) else { return nil }
      return CKMWalletEntry(wallet: wallet, sortDate: Date(), insertInto: context)
    }
  }

}
