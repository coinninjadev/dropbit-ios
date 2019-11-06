//
//  CKMInvitation+CoreDataClass.swift
//  DropBit
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
    self.walletTxTypeCase = WalletTransactionType(addressType: response.addressTypeCase)
    let requestStatus = response.statusCase ?? .new
    self.status = CKMInvitation.statusToPersist(for: requestStatus, side: side)
    self.preauthId = response.metadata?.preauthId

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

  convenience public init(withOutgoingInvitationDTO invitationDTO: OutgoingInvitationDTO,
                          acknowledgmentId: String,
                          insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    let contact = invitationDTO.contact
    self.id = CKMInvitation.unacknowledgementPrefix + acknowledgmentId
    self.btcAmount = invitationDTO.btcPair.btcAmount.asFractionalUnits(of: .BTC)
    self.usdAmountAtTimeOfInvitation = invitationDTO.btcPair.usdAmount.asFractionalUnits(of: .USD)
    self.side = .sender
    self.walletTxTypeCase = invitationDTO.walletTxType
    self.status = .notSent
    self.counterpartyName = contact.displayName
    self.setFlatFee(to: invitationDTO.fee, type: invitationDTO.walletTxType)
    self.configure(withReceiver: contact.asDropBitReceiver, in: context)
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

      if newInvitation.status == .addressProvided, let address = response.address {
        newInvitation.addressProvidedToSender = address
      }

      let parentObject = invitationParentObject(for: response, invitationId: newInvitation.id, in: context)
      parentObject?.invitation = newInvitation
      parentObject?.phoneNumber = newInvitation.phoneNumber
      parentObject?.twitterContact = newInvitation.twitterContact

      return newInvitation
    }
  }

  static private func invitationParentObject(for response: WalletAddressRequestResponse,
                                             invitationId: String,
                                             in context: NSManagedObjectContext) -> InvitationParent? {
    switch response.addressTypeCase {
    case .btc:
      let tx = transaction(for: response, invitationId: invitationId, in: context)
      tx.sortDate = response.createdAt
      // not setting tx.date here since it isn't yet a transaction, so that the display date will fallback to the invitation.sentDate

      tx.isIncoming = tx.calculateIsIncoming(in: context)
      return tx

    case .lightning:
      guard let wallet = CKMWallet.find(in: context) else { return nil }
      let newWalletEntry = CKMWalletEntry(wallet: wallet, sortDate: response.createdAt, insertInto: context)
      return newWalletEntry
    }
  }

  private static func transaction(for response: WalletAddressRequestResponse,
                                  invitationId: String,
                                  in context: NSManagedObjectContext) -> CKMTransaction {
    let maybeTxid: String? = response.txid?.asNilIfEmpty()
    if let txid = maybeTxid, let foundTransaction = CKMTransaction.find(byTxid: txid, in: context) {
      return foundTransaction
    } else {
      let newTransaction = CKMTransaction(insertInto: context)
      let prefixedInvitationId = CKMTransaction.invitationTxidPrefix + invitationId
      newTransaction.txid = maybeTxid ?? prefixedInvitationId
      return newTransaction
    }
  }

  @discardableResult
  static func updateIfExists(withAddressRequestResponse response: WalletAddressRequestResponse,
                             side: WalletAddressRequestSide,
                             isAcknowledged: Bool,
                             in context: NSManagedObjectContext) -> CKMInvitation? {
    let queryId = isAcknowledged ? response.id : CKMInvitation.unacknowledgementPrefix + (response.metadata?.requestId ?? "")
    guard let foundInvitation = find(withId: queryId, in: context) else { return nil }
    foundInvitation.configure(withAddressRequestResponse: response, side: side)
    return foundInvitation
  }

  func configure(withAddressRequestResponse response: WalletAddressRequestResponse, side: WalletAddressRequestSide) {
    self.sentDate = response.createdAt
    self.id = response.id
    self.preauthId = response.metadata?.preauthId

    let requestStatus = response.statusCase ?? .new
    let statusToPersist = CKMInvitation.statusToPersist(for: requestStatus, side: side)
    self.setStatusIfDifferent(to: statusToPersist)

    self.setTxid(to: response.txid) // both txids are optional, placeholder txid is only on CKMTransaction

    if status == .addressProvided, let address = response.address {
      self.addressProvidedToSender = address
    }
  }

  static func statusToPersist(for requestStatus: WalletAddressRequestStatus, side: WalletAddressRequestSide) -> InvitationStatus {
    switch requestStatus {
    case .new:
      switch side {
      case .received: return .addressProvided
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

  static func find(withTxid txid: String, in context: NSManagedObjectContext) -> CKMInvitation? {
    let fetchRequest: NSFetchRequest<CKMInvitation> = CKMInvitation.fetchRequest()
    fetchRequest.predicate = CKPredicate.Invitation.withTxid(txid)
    fetchRequest.fetchLimit = 1

    var ckmInvitation: CKMInvitation?
    context.performAndWait {
      do {
        let invite = try context.fetch(fetchRequest).first
        ckmInvitation = invite
      } catch {
        log.info("failed to find invitation with txid: \(txid)")
      }
    }
    return ckmInvitation
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

  var addressType: WalletAddressType {
    return walletTxTypeCase == .onChain ? .btc : .lightning
  }

}

extension CKMInvitation: DropBitReceiverPersistable {

  var phoneNumber: CKMPhoneNumber? {
    get { return self.counterpartyPhoneNumber }
    set { self.counterpartyPhoneNumber = newValue }
  }

  var twitterContact: CKMTwitterContact? {
    get { return self.counterpartyTwitterContact }
    set { self.counterpartyTwitterContact = newValue }
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
  case addressProvided // formerly accepted

  /// the transaction has been broadcast/received
  case completed

  /// the invitation was canceled, possibly due to insufficient funds or sender canceled
  case canceled

  /// either the sender or receiver did not handle the request within 48 hours of the previous step
  case expired

  public var description: String {
    switch self {
    case .notSent:          return "not sent"
    case .requestSent:      return "request sent"
    case .addressProvided:  return "address provided"
    case .completed:        return "completed"
    case .canceled:         return "canceled"
    case .expired:          return "expired"
    }
  }

}
