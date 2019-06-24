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
                                       acknowledgementId: String,
                                       in context: NSManagedObjectContext) {
    let contact = outgoingDTO.contact

    let invitation = CKMInvitation(insertInto: context)
    invitation.id = CKMInvitation.unacknowledgementPrefix + acknowledgementId
    invitation.btcAmount = outgoingDTO.btcPair.btcAmount.asFractionalUnits(of: .BTC)
    invitation.usdAmountAtTimeOfInvitation = outgoingDTO.btcPair.usdAmount.asFractionalUnits(of: .USD)
    invitation.counterpartyName = contact.displayName
    invitation.status = .notSent
    invitation.setFlatFee(to: outgoingDTO.fee)
    switch contact.identityType {
    case .phone:
      guard let phoneContact = contact as? PhoneContactType,
        let inputs = ManagedPhoneNumberInputs(phoneNumber: phoneContact.globalPhoneNumber) else { return }
      context.performAndWait {
        let phoneNumber = CKMPhoneNumber.findOrCreate(withInputs: inputs,
                                                      phoneNumberHash: phoneContact.phoneNumberHash, in: context)
        invitation.counterpartyPhoneNumber = phoneNumber
      }
    case.twitter:
      guard let twitterContact = contact as? TwitterContactType else { return }
      let managedTwitterContact = CKMTwitterContact.findOrCreate(with: twitterContact, in: context)
      invitation.counterpartyTwitterContact = managedTwitterContact
    }
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
    transaction.configureNewSenderSharedPayload(with: outgoingTransactionData.sharedPayloadDTO, in: context)
    invitation.transaction = transaction
    invitation.counterpartyTwitterContact = transaction.twitterContact
    invitation.counterpartyPhoneNumber = transaction.phoneNumber
  }

}
