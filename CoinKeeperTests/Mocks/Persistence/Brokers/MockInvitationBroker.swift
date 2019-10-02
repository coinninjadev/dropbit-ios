//
//  MockInvitationBroker.swift
//  DropBitTests
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import Foundation
import PromiseKit
@testable import DropBit

class MockInvitationBroker: CKPersistenceBroker, InvitationBrokerType {

  var unacknowledgedInvitations: [CKMInvitation] = []
  func getUnacknowledgedInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
    return unacknowledgedInvitations
  }

  func getAllInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
    return []
  }

  func persistUnacknowledgedInvitation(withDTO invitationDTO: OutgoingInvitationDTO,
                                       acknowledgmentId: String,
                                       in context: NSManagedObjectContext) { }

  var addressValuesForReceivedPendingDropBits: [String] = []
  func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String] {
    return addressValuesForReceivedPendingDropBits
  }

  func acknowledgeInvitation(with outgoingTransactionData: OutgoingTransactionData,
                             response: WalletAddressRequestResponse,
                             in context: NSManagedObjectContext) { }

}
