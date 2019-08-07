//
//  CKMInvitation+CoreDataClass.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CKMInvitation)
public class CKMInvitation: NSManagedObject {

  static let unacknowledgementPrefix = "UnacknowledgementId_"

  convenience public init(withAddressRequestResponse response: WalletAddressRequestResponse,
                          side: WalletAddressRequestSide,
                          insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)

    self.id = response.id
    self.btcAmount = response.metadata?.amount?.btc ?? 0
    self.usdAmountAtTimeOfInvitation = response.metadata?.amount?.usd ?? 0
    self.counterpartyName = nil
    self.sentDate = response.createdAt
    self.side = InvitationSide(requestSide: side)
    let requestStatus = response.statusCase ?? .new
    self.status = CKMInvitation.statusToPersist(for: requestStatus, side: side)

    // Associate this invitation with phone number of the opposite side
    let counterparty: MetadataParticipant?
    switch side {
    case .received: counterparty = response.metadata?.sender
    case .sent:     counterparty = response.metadata?.receiver
    }

    // Associate this invitation with twitter contact of the opposite side
    if let unwrappedCounterparty = counterparty, let type = UserIdentityType(rawValue: unwrappedCounterparty.type) {

      switch type {
      case .phone:
        self.counterpartyPhoneNumber = counterparty.flatMap {
          CKMPhoneNumber.findOrCreate(withMetadataParticipant: $0, in: context)
        }
      case .twitter:
        self.counterpartyTwitterContact = counterparty.flatMap({ (participant: MetadataParticipant) -> CKMTwitterContact? in
          let identity = UserIdentityBody(participant: participant)
          var twitterContact = TwitterContact(twitterUser: identity.twitterUser())
          twitterContact.kind = .registeredUser
          let ckmTwitterContact = CKMTwitterContact.findOrCreate(with: twitterContact, in: context)
          return ckmTwitterContact
        })
      }
    }

    self.setTxid(to: response.txid)
  }

  convenience public init(withOutgoingInvitationDTO outgoingDTO: OutgoingInvitationDTO,
                          acknowledgmentId: String,
                          insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    let contact = outgoingDTO.contact
    self.id = CKMInvitation.unacknowledgementPrefix + acknowledgmentId
    self.btcAmount = outgoingDTO.btcPair.btcAmount.asFractionalUnits(of: .BTC)
    self.usdAmountAtTimeOfInvitation = outgoingDTO.btcPair.usdAmount.asFractionalUnits(of: .USD)
    self.side = .sender
    self.status = .notSent
    self.counterpartyName = contact.displayName
    self.setFlatFee(to: outgoingDTO.fee)

    switch contact.identityType {
    case .phone:
      guard let phoneContact = contact as? PhoneContactType,
        let inputs = ManagedPhoneNumberInputs(phoneNumber: phoneContact.globalPhoneNumber)
        else { return }
      self.counterpartyPhoneNumber = CKMPhoneNumber.findOrCreate(withInputs: inputs,
                                                            phoneNumberHash: phoneContact.phoneNumberHash,
                                                            in: context)
    case.twitter:
      guard let twitterContact = contact as? TwitterContactType else { return }
      let managedTwitterContact = CKMTwitterContact.findOrCreate(with: twitterContact, in: context)
      self.counterpartyTwitterContact = managedTwitterContact
    }
  }

  var completed: Bool {
    return status == .completed
  }

  var totalPendingAmount: Int {
    return btcAmount + fees
  }

  var isFulfillable: Bool {
    switch status {
    case .completed, .canceled, .expired: return false
    default: return true
    }
  }

  /// Use only for received address requests
  @discardableResult
  static func updateOrCreate(withReceivedAddressRequestResponse response: WalletAddressRequestResponse,
                             in context: NSManagedObjectContext) -> CKMInvitation {
    if let updatedInvitation = updateIfExists(withAddressRequestResponse: response, side: .received, isAcknowledged: true, in: context) {
      return updatedInvitation

    } else {
      // This creation logic mainly handles the receiver side, but may be elaborated upon for the sender in the future

      let newInvitation = CKMInvitation(withAddressRequestResponse: response, side: .received, insertInto: context)

      let maybeTxid = response.txid?.asNilIfEmpty()
      let tx = maybeTxid.flatMap { CKMTransaction.find(byTxid: $0, in: context) } ?? CKMTransaction(insertInto: context)

      tx.txid = maybeTxid ?? CKMTransaction.prefixedTxid(for: newInvitation)

      tx.sortDate = response.createdAt
      // not setting newTx.date here since it isn't yet a transaction, so that the display date will fallback to the invitation.sentDate

      tx.invitation = newInvitation
      tx.isIncoming = tx.calculateIsIncoming(in: context)

      if newInvitation.status == .addressSent, let address = response.address {
        newInvitation.addressProvidedToSender = address
      }

      return newInvitation
    }
  }

  @discardableResult
  static func updateIfExists(withAddressRequestResponse response: WalletAddressRequestResponse,
                             side: WalletAddressRequestSide,
                             isAcknowledged: Bool,
                             in context: NSManagedObjectContext) -> CKMInvitation? {
    let queryId = isAcknowledged ? response.id : CKMInvitation.unacknowledgementPrefix + (response.metadata?.requestId ?? "")
    guard let foundInvitation = find(withId: queryId, in: context) else { return nil }
    foundInvitation.sentDate = response.createdAt
    foundInvitation.id = response.id

    let requestStatus = response.statusCase ?? .new
    let statusToPersist = CKMInvitation.statusToPersist(for: requestStatus, side: side)
    foundInvitation.setStatusIfDifferent(to: statusToPersist)

    foundInvitation.setTxid(to: response.txid) // both txids are optional, placeholder txid is only on CKMTransaction

    if foundInvitation.status == .addressSent, let address = response.address {
      foundInvitation.addressProvidedToSender = address
    }

    return foundInvitation
  }

  static func statusToPersist(for requestStatus: WalletAddressRequestStatus, side: WalletAddressRequestSide) -> InvitationStatus {
    switch requestStatus {
    case .new:
      switch side {
      case .received: return .addressSent
      case .sent:     return .requestSent
      }

    case .completed:  return .completed
    case .canceled:   return .canceled
    case .expired:    return .expired
    }
  }

  /**
   Currently, this returns all invitations with one of the statuses, regardless of wallet
   because that relationship is difficult to query for.
   */
  static func find(withStatuses statuses: [InvitationStatus], in context: NSManagedObjectContext) -> [CKMInvitation] {
    let fetchRequest: NSFetchRequest<CKMInvitation> = CKMInvitation.fetchRequest()
    fetchRequest.predicate = CKPredicate.Invitation.withStatuses(statuses)

    var result: [CKMInvitation] = []
    context.performAndWait {
      do {
        let results = try context.fetch(fetchRequest)
        result = results
      } catch {
        result = []
      }
    }
    return result
  }

  static func find(withId id: String, in context: NSManagedObjectContext) -> CKMInvitation? {
    let fetchRequest: NSFetchRequest<CKMInvitation> = CKMInvitation.fetchRequest()
    fetchRequest.predicate = CKPredicate.Invitation.withId(id)
    fetchRequest.fetchLimit = 1

    var ckmInvitation: CKMInvitation?
    context.performAndWait {
      do {
        let results = try context.fetch(fetchRequest)
        ckmInvitation = results.first
      } catch {
        ckmInvitation = nil
      }
    }
    return ckmInvitation
  }

  static func findUpdatedFulfilledReceivedAddressRequests(in context: NSManagedObjectContext) -> [CKMInvitation] {
    let fetchRequest: NSFetchRequest<CKMInvitation> = CKMInvitation.fetchRequest()
    fetchRequest.predicate = CKPredicate.Invitation.updatedFulfilledReceivedAddressRequests()

    var result: [CKMInvitation] = []
    context.performAndWait {
      do {
        result = try context.fetch(fetchRequest)
      } catch {
        result = []
      }
    }
    return result
  }

  static func findUnacknowledgedInvitation(in context: NSManagedObjectContext, with id: String) -> CKMInvitation? {
    let fetchRequest: NSFetchRequest<CKMInvitation> = CKMInvitation.fetchRequest()
    fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [
      CKPredicate.Invitation.invitationHasUnacknowledgedPrefix(),
      CKPredicate.Invitation.withId(CKMInvitation.unacknowledgementPrefix + id)
      ])

    var result: CKMInvitation?
    context.performAndWait {
      do {
        result = try context.fetch(fetchRequest).first
      } catch {
        result = nil
      }
    }
    return result
  }

  static func getAllInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
    let fetchRequest: NSFetchRequest<CKMInvitation> = CKMInvitation.fetchRequest()

    var result: [CKMInvitation] = []
    context.performAndWait {
      do {
        result = try context.fetch(fetchRequest)
      } catch {
        result = []
      }
    }

    return result
  }

  static func findUnacknowledgedInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
    let fetchRequest: NSFetchRequest<CKMInvitation> = CKMInvitation.fetchRequest()
    fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [
      CKPredicate.Invitation.invitationHasUnacknowledgedPrefix(), CKPredicate.Invitation.withStatuses([.notSent])
      ])

    var result: [CKMInvitation] = []
    context.performAndWait {
      do {
        result = try context.fetch(fetchRequest)
      } catch {
        result = []
      }
    }

    return result
  }

  static func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String] {
    let results = findUpdatedFulfilledReceivedAddressRequests(in: context)
    return results.compactMap { $0.addressProvidedToSender }
  }

}

extension CKMInvitation: AddressRequestUpdateDisplayable {
  var fiatAmount: Int {
    return self.usdAmountAtTimeOfInvitation
  }

  var addressRequestId: String {
    return self.id
  }

  var senderName: String? {
    switch side {
    case .sender:   return nil
    case .receiver: return counterpartyName
    }
  }

  var senderPhoneNumber: GlobalPhoneNumber? {
    switch side {
    case .sender:   return nil
    case .receiver: return counterpartyPhoneNumber?.asGlobalPhoneNumber
    }
  }

  var senderHandle: String? {
    switch side {
    case .sender:   return nil
    case .receiver: return counterpartyTwitterContact?.formattedScreenName
    }
  }

  var receiverName: String? {
    switch side {
    case .sender:   return counterpartyName
    case .receiver: return nil
    }
  }

  var receiverPhoneNumber: GlobalPhoneNumber? {
    switch side {
    case .sender:   return counterpartyPhoneNumber?.asGlobalPhoneNumber
    case .receiver: return nil
    }
  }

  var receiverHandle: String? {
    switch side {
    case .sender:   return counterpartyTwitterContact?.formattedScreenName
    case .receiver: return nil
    }
  }

}

@objc public enum InvitationSide: Int16, CustomStringConvertible {
  case sender
  case receiver

  init(requestSide: WalletAddressRequestSide) {
    switch requestSide {
    case .sent:     self = .sender
    case .received: self = .receiver
    }
  }

  public var description: String {
    switch self {
    case .sender:   return "sender"
    case .receiver: return "receiver"
    }
  }

}

@objc public enum InvitationStatus: Int16, CustomStringConvertible {
  /// the address request has not yet been sent to the server
  case notSent = 0

  /// sender has sent address request, waiting for receiver to provide address
  case requestSent // formerly pending

  /// receiver has updated the address request with an address, waiting for transaction
  case addressSent // formerly accepted

  /// the transaction has been broadcast/received
  case completed

  /// the invitation was canceled, possibly due to insufficient funds or sender canceled
  case canceled

  /// either the sender or receiver did not handle the request within 48 hours of the previous step
  case expired

  public var description: String {
    switch self {
    case .notSent:      return "not sent"
    case .requestSent:  return "request sent"
    case .addressSent:  return "address sent"
    case .completed:    return "completed"
    case .canceled:     return "canceled"
    case .expired:      return "expired"
    }
  }

}
